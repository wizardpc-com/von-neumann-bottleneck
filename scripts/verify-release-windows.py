#!/usr/bin/env python3
"""Read exact draft assets and test frozen Windows binaries on a disposable runner."""
import argparse
from contextlib import closing, contextmanager
from datetime import datetime, timedelta, timezone
import hashlib
from http.client import HTTPConnection, HTTPSConnection, HTTPException
import importlib.util
import json
import os
from pathlib import Path
import re
import shutil
import socket
import sqlite3
import stat
import subprocess
import sys
import time
from urllib.parse import parse_qs, urlsplit
import uuid
import zipfile


SCRIPTS = Path(__file__).resolve().parent
ROOT = SCRIPTS.parent
SPEC = importlib.util.spec_from_file_location('package_feedback', SCRIPTS / 'verify-package-feedback.py')
PACKAGE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(PACKAGE)
LIMIT = 1 << 30
NOTE = 'SYNTHETIC hosted Windows release check'
PUBLIC_ORIGIN = 'https://feedback.yanruiqing.com:8443'
ASSET_HOSTS = {'release-assets.githubusercontent.com', 'objects.githubusercontent.com'}
ASSET_PATTERN = r'Von-Neumann-Bottleneck-Windows-[A-Za-z0-9.-]+\.zip'
CAPABILITY_SECRETS = {'game':'VNB_WINDOWS_DRAFT_GAME_URL','test':'VNB_WINDOWS_DRAFT_TEST_URL'}


def sha256(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write_json(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def pinned(value, pattern, label):
    if not re.fullmatch(pattern, value):
        raise ValueError(f'Invalid {label}')
    return value


def gh_get(path, accept='application/vnd.github+json', destination=None, missing_ok=False):
    command = ['gh', 'api', '--method', 'GET', '--hostname', 'github.com',
               '-H', 'Accept: ' + accept, '-H', 'X-GitHub-Api-Version: 2022-11-28', path]
    if destination is not None:
        with destination.open('xb') as stream:
            result = subprocess.run(command + ['--allow-escape-sequences'], stdout=stream,
                                    stderr=subprocess.PIPE, timeout=300)
    else:
        result = subprocess.run(command, capture_output=True, timeout=45)
    if result.returncode:
        error = result.stderr.decode('utf-8', errors='replace').strip()
        if missing_ok and 'HTTP 404' in error:
            return None
        raise RuntimeError(f'Read-only GitHub request failed for {path}: {error}')
    if destination is None:
        return json.loads(result.stdout)


def verify_draft(repository, release, release_id, tag, commit):
    if release.get('id') != int(release_id) or release.get('tag_name') != tag or release.get('draft') is not True:
        raise ValueError('Release ID/tag must identify the exact draft')
    reference = gh_get(f'repos/{repository}/git/ref/tags/{tag}', missing_ok=True)
    if reference is None:
        if release.get('target_commitish') != commit:
            raise ValueError('An untagged draft must name the full frozen commit as target_commitish')
        return
    target = reference['object']
    for _ in range(8):
        if target['type'] != 'tag':
            break
        oid = pinned(target['sha'], r'[0-9a-f]{40}', 'annotated tag SHA')
        target = gh_get(f'repos/{repository}/git/tags/{oid}')['object']
    if target['type'] != 'commit' or target['sha'] != commit:
        raise ValueError('Draft tag does not resolve to the pinned commit')


def asset_identity(release, name, digest):
    matching = [asset for asset in release['assets'] if asset['name'] == name]
    if len(matching) != 1:
        raise ValueError(f'Expected one uploaded draft asset named {name}')
    asset = matching[0]
    if (asset['state'] != 'uploaded' or type(asset['id']) is not int or asset['id'] < 1
            or type(asset['size']) is not int or not 0 < asset['size'] <= LIMIT
            or asset.get('digest') not in (None, 'sha256:' + digest)):
        raise ValueError(f'Draft asset metadata does not match pin for {name}')
    return {'id':asset['id'], 'name':name, 'bytes':asset['size'], 'sha256':digest}


def validate_capability(value, *, minimum_seconds=30):
    """Accept only the HTTPS, expiring, read-only GitHub single-blob redirect."""
    try:
        url = urlsplit(value)
        query = parse_qs(url.query,max_num_fields=40)
        expiration = datetime.fromisoformat(query['se'][0].replace('Z','+00:00'))
        duration = expiration - datetime.now(timezone.utc)
        if (url.scheme!='https' or url.hostname not in ASSET_HOSTS or url.port not in (None,443)
                or url.username is not None or url.password is not None or url.fragment
                or not url.path.startswith('/github-production-release-asset')
                or query.get('sp')!=['r'] or query.get('sr')!=['b'] or not query.get('sig')
                or len(query['se'])!=1 or not timedelta(seconds=minimum_seconds)<duration<timedelta(hours=2)):
            raise ValueError
    except (KeyError, IndexError, TypeError, ValueError, OverflowError):
        raise ValueError('Expected a valid, short-lived GitHub read-only asset capability') from None
    return url, expiration


def download_capability(value, destination):
    url, _ = validate_capability(value)
    try:
        with closing(HTTPSConnection(url.hostname,timeout=20)) as client:
            client.request('GET',url.path+'?'+url.query)
            with client.getresponse() as response:
                if response.status!=200:
                    raise ValueError(f'GitHub capability download returned HTTP {response.status}')
                length=response.getheader('Content-Length','')
                if not length.isdecimal() or not 0<int(length)<=LIMIT:
                    raise ValueError('Unexpected GitHub capability asset size')
                copied=0
                with destination.open('xb') as output:
                    for block in iter(lambda: response.read(1024*1024),b''):
                        copied+=len(block)
                        if copied>int(length):
                            raise ValueError('GitHub capability response exceeded its declared size')
                        output.write(block)
                if copied!=int(length):
                    raise ValueError('GitHub capability asset was truncated')
                return copied
    except (OSError, HTTPException):
        raise RuntimeError('GitHub capability download failed; check expiry and runner connectivity') from None


def fetch(work, *, capabilities=False):
    repository = pinned(os.environ['GITHUB_REPOSITORY'], r'[\w.-]+/[\w.-]+', 'repository')
    release_id = pinned(os.environ['VNB_RELEASE_ID'], r'[1-9][0-9]*', 'draft ID')
    tag = pinned(os.environ['VNB_RELEASE_TAG'], r'v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?', 'release tag')
    commit = pinned(os.environ['VNB_RELEASE_COMMIT'], r'[0-9a-f]{40}', 'source commit')
    records = {}
    for role in ('game', 'test'):
        name = pinned(os.environ[f'VNB_{role.upper()}_ASSET'], ASSET_PATTERN, 'asset name')
        digest = pinned(os.environ[f'VNB_{role.upper()}_SHA256'].lower(), r'[0-9a-f]{64}', 'asset digest')
        records[role] = {'name':name, 'sha256':digest}
    if records['game']['name']==records['test']['name'] or records['game']['sha256']==records['test']['sha256']:
        raise ValueError('Game and Test require distinct assets')
    if not capabilities:
        if not os.environ.get('GH_TOKEN'):
            raise RuntimeError('The built-in GitHub runner token is required in the download step')
        release = gh_get(f'repos/{repository}/releases/{release_id}')
        verify_draft(repository, release, release_id, tag, commit)
        records={role:asset_identity(release, asset['name'], asset['sha256']) for role,asset in records.items()}
        if records['game']['id']==records['test']['id']:
            raise ValueError('Game and Test require distinct draft asset IDs')
    work.mkdir()
    for role, asset in records.items():
        destination = work / (role + '.zip')
        if capabilities:
            value=os.environ.pop(f'VNB_{role.upper()}_ASSET_CAPABILITY','')
            asset['bytes']=download_capability(value,destination)
        else:
            gh_get(f'repos/{repository}/releases/assets/{asset["id"]}', 'application/octet-stream', destination)
        if destination.stat().st_size != asset['bytes'] or sha256(destination) != asset['sha256']:
            raise ValueError(f'Downloaded {role} asset differs from the pinned bytes')
    write_json(work/'downloads.json', {'repository':repository,'release_id':release_id,'tag':tag,
                                      'source_commit':commit,'assets':records,
                                      'download_identity':'operator-resolved capabilities' if capabilities else 'runner draft API'})


def verify_manifest(manifest, role, tag, commit, asset_name):
    batch = pinned(manifest.get('test_batch',''), r'[A-Za-z0-9-]{1,40}', 'package batch')
    profile = 'Edition' + role.title()
    build = f'vnb-{role}-release-{tag}-{batch}-{commit[:12]}'
    expected = {'source_commit':commit,'release_version':tag,'display_version':tag[1:],
                'edition':role,'edition_name':role.title()+' Edition','build_id':build,
                'save_profile':profile,'platform':'Windows',
                'content_count':60,'content_version':'tasks-20261013-journey-v1',
                'mode_locked':True,'player_release':True,'save_migration':False,
                'save_directories':[f'VonNeumannBottleneckCandidates/{d}/{profile}' for d in ('representation','service')],
                'access_policy':'earned' if role=='game' else 'all-task-entrances'}
    if (any(manifest.get(k) != v for k,v in expected.items())
            or manifest.get('mode_locked') is not True or manifest.get('player_release') is not True
            or manifest.get('save_migration') is not False or type(manifest.get('content_count')) is not int
            or asset_name != f'Von-Neumann-Bottleneck-Windows-{build}.zip'
            or not re.fullmatch(r'4\.7\.1\.stable\.official\.[0-9a-f]{9,40}',manifest.get('engine',''))
            or any(manifest.get(key) for key in ('player_feedback_pilot','network_feedback_test','local_acceptance_only'))):
        raise ValueError(f'{role} package manifest does not match the pinned release identity')
    if role == 'game':
        if (manifest.get('public_game_feedback') is not True or manifest.get('community_feedback_enabled') is not False
                or manifest.get('feedback_default_source') != 'external_player' or manifest.get('feedback_source_batch') != batch
                or manifest.get('feedback_endpoint') != PUBLIC_ORIGIN+'/v1'
                or manifest.get('privacy_url') != PUBLIC_ORIGIN+'/privacy-player.html'):
            raise ValueError('Game package lacks the online player feedback identity')
    elif set(manifest) & {'feedback_endpoint','privacy_url','feedback_default_source','feedback_source_batch',
                          'public_game_feedback','community_feedback_enabled'}:
        raise ValueError('Test package must be offline')
    return profile


def unpack(archive, destination, role, identity):
    pin = identity['assets'][role]
    if archive.stat().st_size != pin['bytes'] or sha256(archive) != pin['sha256']:
        raise ValueError(f'{role} archive changed after download')
    destination.mkdir()
    with zipfile.ZipFile(archive) as package:
        entries = package.infolist()
        names = [entry.filename for entry in entries]
        if (not 0 < len(entries) <= 100 or sum(entry.file_size for entry in entries) > LIMIT
                or len(set(name.casefold() for name in names)) != len(names)):
            raise ValueError('Unexpected Windows ZIP size or duplicate entries')
        for entry in entries:
            if (not re.fullmatch(r'Windows/[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*\.(?:exe|pck|txt|json)',entry.filename)
                    or entry.flag_bits & 1 or stat.S_IFMT(entry.external_attr >> 16) not in (0, stat.S_IFREG)):
                raise ValueError('Unexpected Windows ZIP member or file type')
        leaf = f'Von-Neumann-Bottleneck-{role.title()}.exe'
        manifest_name = 'Windows/BUILD-MANIFEST.json'
        if manifest_name not in names or f'Windows/{leaf}' not in names:
            raise ValueError('Windows manifest or expected executable is missing')
        if package.getinfo(manifest_name).file_size > 65536:
            raise ValueError('Unexpectedly large platform manifest')
        manifest = json.loads(package.read(manifest_name))
        verify_manifest(manifest, role, identity['tag'], identity['source_commit'], pin['name'])
        inventory = manifest['files_sha256']
        if set(inventory) != {name.split('/',1)[1] for name in names if name != manifest_name}:
            raise ValueError('ZIP inventory differs from the platform manifest')
        allowed_binary = {leaf, leaf[:-4]+'.pck'}
        if any(name.lower().endswith(('.exe','.pck')) and name not in allowed_binary for name in inventory):
            raise ValueError('Unexpected additional Windows executable or pack')
        if any(name.partition('.')[0].upper() in {'CON','PRN','AUX','NUL',*(f'COM{i}' for i in range(1,10)),
                                                      *(f'LPT{i}' for i in range(1,10))} for name in inventory):
            raise ValueError('Unexpected reserved Windows file name')
        for entry in entries:
            name = entry.filename.split('/',1)[1]
            path = destination / name
            with package.open(entry) as source, path.open('xb') as output:
                shutil.copyfileobj(source,output)
            if name in inventory and sha256(path) != inventory[name]:
                raise ValueError(f'Frozen package file hash mismatch: {name}')
    return destination/leaf, manifest


@contextmanager
def guarded_binary(binary):
    rule = 'VNBReleaseQA-' + uuid.uuid4().hex
    command = ['powershell.exe','-NoProfile','-NonInteractive','-File',str(SCRIPTS/'windows-release-firewall.ps1')]
    try:
        subprocess.run(command+['-Operation','Install','-Rule',rule,'-Program',str(binary)],check=True,timeout=60)
        yield
    finally:
        subprocess.run(command+['-Operation','Remove','-Rule',rule,'-Program',str(binary)],check=True,timeout=60)


def runner_environment(runtime):
    system = {'SYSTEMROOT','WINDIR','SYSTEMDRIVE','COMSPEC','PATH','PATHEXT',
              'PROCESSOR_ARCHITECTURE','NUMBER_OF_PROCESSORS','OS'}
    environment = {k:v for k,v in os.environ.items() if k.upper() in system}
    for variable in ('APPDATA','LOCALAPPDATA','USERPROFILE','TMP','TEMP'):
        path=runtime/variable
        path.mkdir(parents=True)
        environment[variable]=str(path)
    return environment


def write_override(path, scene, profile_dir, output, expected, endpoint, phase):
    if endpoint:
        PACKAGE.loopback_port(endpoint)
    data = {'phase':phase,'output':output.as_posix(),'user_dir':profile_dir.as_posix(),
            'endpoint':endpoint,'identity':expected}
    config = ('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='
              +json.dumps(expected['qa_dir'],ensure_ascii=False)+'\nrun/main_scene='+json.dumps(scene.as_posix(),ensure_ascii=False)
              +'\nfeedback_endpoint='+json.dumps(endpoint)+'\nfeedback_privacy_url=""\nfeedback_source_batch="HostedWindowsReleaseQA"'
              +'\n\n[windows_release_qa]\nconfiguration='+json.dumps(json.dumps(data,ensure_ascii=False),ensure_ascii=False)+'\n')
    path.write_text(config,encoding='utf-8')


def verify_phase(binary, scene, profile_dir, work, expected, endpoint, phase, env):
    override=binary.parent/'override.cfg'
    if override.exists():
        raise ValueError('Unexpected executable override before launch')
    log=work/(phase+'.engine.log')
    write_override(override,scene,profile_dir,work,expected,endpoint,phase)
    try:
        process=subprocess.run([str(binary),'--headless','--log-file',str(log),'--',
                                '--enable-playtest-feedback','--playtest-source=automated'],
                               cwd=binary.parent,env=env,capture_output=True,text=True,encoding='utf-8',
                               errors='replace',timeout=90)
    finally:
        override.unlink(missing_ok=True)
    stdout=process.stdout+process.stderr
    (work/(phase+'.log')).write_text(stdout,encoding='utf-8')
    if log.exists():
        stdout+='\n'+log.read_text(encoding='utf-8',errors='replace')
    errors=[line for line in stdout.splitlines() if 'ERROR:' in line and 'root certificate store' not in line]
    if process.returncode or errors or f'PASS: Windows release {phase}' not in stdout:
        print('\n'.join(errors[:12]),flush=True)
        raise RuntimeError(f'{expected["edition"]} {phase} failed (exit {process.returncode})')
    report=read_json(work/(phase+'.json'))
    if (report.get('passed') is not True or report.get('phase')!=phase
            or Path(report['user_dir']).resolve()!=profile_dir.resolve()):
        raise ValueError('Runtime receipt does not match the isolated package and phase')
    return report


@contextmanager
def receiver(work, port):
    database = work/'synthetic.sqlite'
    with (work/'receiver.log').open('w',encoding='utf-8') as log:
        environment = {key:value for key,value in os.environ.items() if not key.upper().startswith('VNB_')}
        child = subprocess.Popen([sys.executable,str(ROOT/'server/feedback_server.py'),'--host','127.0.0.1',
                                  '--port',str(port),'--database',str(database)],
                                 stdout=log,stderr=subprocess.STDOUT,env=environment)
        try:
            for _ in range(60):
                if child.poll() is not None:
                    raise RuntimeError('Loopback receiver exited before readiness')
                client=HTTPConnection('127.0.0.1',port,timeout=0.5)
                try:
                    client.request('GET','/v1/health')
                    if client.getresponse().status == 200:
                        break
                except OSError:
                    time.sleep(0.1)
                finally:
                    client.close()
            else:
                raise RuntimeError('Loopback receiver did not become ready')
            yield database
        finally:
            child.terminate()
            try:
                child.wait(timeout=5)
            except subprocess.TimeoutExpired:
                child.kill()
                child.wait()


def verify_opinion(database, event_id, manifest):
    with closing(sqlite3.connect(database)) as data:
        rows = data.execute('SELECT id,kind,body FROM events').fetchall()
    if len(rows)!=1 or rows[0][:2]!=(event_id,'feedback'):
        raise ValueError('Expected exactly one matching synthetic opinion in the loopback receiver')
    payload=json.loads(rows[0][2])['payload']
    expected={'chapter_id':'hardware_foundations','level_id':'tutorial','mode':'game','source':'automated',
              'source_batch':'HostedWindowsReleaseQA','note':NOTE,'build_version':manifest['display_version'],
              'source_commit':manifest['source_commit'],'test_batch':manifest['test_batch'],'sharing_mode':'opinion'}
    if any(payload.get(k)!=v for k,v in expected.items()) or {'program_source','examples','output','intent','work'} & payload.keys():
        raise ValueError('Synthetic loopback opinion has incorrect attribution or contains protected work')


def verify(work):
    for key in ('APPDATA','LOCALAPPDATA','USERPROFILE'):
        if not os.environ.get(key):
            raise RuntimeError(f'Missing hosted runner path {key}')
    roots = {Path(os.environ[k]) for k in ('APPDATA','LOCALAPPDATA')} | {
        Path(os.environ['USERPROFILE'])/'AppData'/folder for folder in ('Roaming','Local')}
    protected = {root/relative for root in roots
                 for relative in ('Godot/app_userdata','VonNeumannBottleneckCandidates')}
    if any(path.exists() for path in protected):
        raise RuntimeError('Runner has existing Godot player paths. No binary was launched.')
    identity=read_json(work/'downloads.json')
    prepared = {}
    for role in ('game','test'):
        stage=work/role
        stage.mkdir()
        prepared[role]=unpack(work/(role+'.zip'),stage/'copy',role,identity)
    for key in ('engine','test_batch','content_version'):
        if prepared['game'][1].get(key) != prepared['test'][1].get(key):
            raise ValueError(f'Game and Test release manifests disagree on {key}')
    for role,(binary,manifest) in prepared.items():
        stage=work/role
        sidecar=binary.with_suffix('.pck')
        if not sidecar.exists():
            PACKAGE.embedded_pck_sha256(binary)
        script=stage/'probe.gd'
        shutil.copyfile(SCRIPTS/'windows-release-probe.gd',script)
        scene=stage/'probe.tscn'
        PACKAGE.write_probe_scene(scene,script)
        env=runner_environment(stage/'runtime')
        qa_dir='HostedWindowsReleaseQA/VonNeumannBottleneckCandidates/representation/'+manifest['save_profile']
        profile_dir=Path(env['APPDATA'])/qa_dir
        expected={k:manifest[k] for k in ('edition','display_version','source_commit','test_batch',
                                         'build_id','save_profile','engine')}
        expected['qa_dir']=qa_dir
        try:
            with guarded_binary(binary):
                if role == 'game':
                    with socket.socket() as reservation:
                        reservation.setsockopt(socket.SOL_SOCKET,socket.SO_EXCLUSIVEADDRUSE,1)
                        reservation.bind(('127.0.0.1',0))
                        port=reservation.getsockname()[1]
                        endpoint=f'http://127.0.0.1:{port}'
                        first=verify_phase(binary,scene,profile_dir,stage,expected,endpoint,'write',env)
                    with receiver(stage,port) as database:
                        second=verify_phase(binary,scene,profile_dir,stage,expected,endpoint,'restart',env)
                        verify_opinion(database,first['feedback_id'],manifest)
                else:
                    first=verify_phase(binary,scene,profile_dir,stage,expected,'','write',env)
                    second=verify_phase(binary,scene,profile_dir,stage,expected,'','restart',env)
                    with zipfile.ZipFile(stage/'offline-feedback.zip') as bundle:
                        case_id=first['feedback_id']
                        notes=bundle.read(f'cases/{case_id}/notes.jsonl').decode('utf-8').splitlines()
                        if json.loads(notes[-1])['note']!=NOTE:
                            raise ValueError('Offline ZIP does not preserve the restarted note')
        finally:
            if any(path.exists() for path in protected):
                raise RuntimeError('A package created files in an unisolated Godot player path')
        if (first['pid']==second['pid'] or first['workbench_sha256']!=second['workbench_sha256']
                or first['feedback_id']!=second['feedback_id']
                or any(sha256(binary.parent/name)!=digest for name,digest in manifest['files_sha256'].items())
                or sha256(work/(role+'.zip'))!=identity['assets'][role]['sha256']):
            raise ValueError(f'{role} restart/preservation did not match')
        write_json(stage/'result.json',{'passed':True,'asset':identity['assets'][role],
                   'build_id':manifest['build_id'],'edition':role,'write':first,'restart':second})
        print(f'PASS: {role} frozen Windows executable, isolated save/restart and synthetic feedback '
              f'(ZIP SHA-256 {identity["assets"][role]["sha256"]})',flush=True)
    write_json(work/'result.json',{'passed':True, **identity,'scope':'Windows hosted headless binary; synthetic local feedback only'})


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('phase',choices=('fetch','verify'))
    parser.add_argument('--capabilities',action='store_true',help='Use only the dedicated short-lived GitHub asset secrets')
    args=parser.parse_args()
    if sys.platform!='win32' or os.environ.get('RUNNER_ENVIRONMENT')!='github-hosted':
        parser.error('Requires the disposable GitHub-hosted Windows runner')
    run=pinned(os.environ['GITHUB_RUN_ID'],r'[1-9][0-9]*','workflow run')
    attempt=pinned(os.environ['GITHUB_RUN_ATTEMPT'],r'[1-9][0-9]*','workflow attempt')
    work=Path(os.environ['RUNNER_TEMP']).resolve()/f'vnb-release-qa-{run}-{attempt}'
    if args.phase=='fetch':
        fetch(work,capabilities=args.capabilities)
    elif args.capabilities:
        parser.error('--capabilities is only valid for fetch')
    else:
        verify(work)


if __name__=='__main__':
    main()

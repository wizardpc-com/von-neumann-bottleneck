#!/usr/bin/env python3
"""Read exact release assets and test frozen Windows binaries on a disposable runner."""
import argparse
from contextlib import closing, contextmanager
from datetime import datetime, timedelta, timezone
import hashlib
from http.client import HTTPConnection, HTTPSConnection, HTTPException
import importlib.util
import ipaddress
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
FINAL_TAG = 'v0.6.1-playtest.2'
FINAL_BATCH = 'Players061-Release2'
BASELINE = {
    'repository': 'wizardpc-com/von-neumann-bottleneck',
    'release_id': '454479788',
    'tag': 'v0.6.1-playtest.1',
    'source_commit': 'c4a09364748410370d605e55e610943b5c69a72b',
    'assets': {
        'game': {
            'name': 'Von-Neumann-Bottleneck-Windows-vnb-game-release-v0.6.1-playtest.1-Players061-Release1-c4a093647484.zip',
            'bytes': 211972635,
            'sha256': 'b56c56913bccfc948af7a715686429c118e61fe87a008d06ee138bc94b9323b8',
        },
        'test': {
            'name': 'Von-Neumann-Bottleneck-Windows-vnb-test-release-v0.6.1-playtest.1-Players061-Release1-c4a093647484.zip',
            'bytes': 211972258,
            'sha256': 'a88871d53304a99238295bed1d3a33da8ec3431a823116b44f4f744f3f797319',
        },
    },
}
BLOCKED_PREFIXES = {
    'IPv4': tuple(str(prefix) for prefix in ipaddress.ip_network('0.0.0.0/0').address_exclude(
        ipaddress.ip_network('127.0.0.0/8'))),
    'IPv6': ('::/1','8000::/1'),
}


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
    environment = {key:value for key,value in os.environ.items() if key!='GH_DEBUG'}
    environment['GH_PROMPT_DISABLED']='1'
    if destination is not None:
        with destination.open('xb') as stream:
            result = subprocess.run(command + ['--allow-escape-sequences'], stdout=stream,
                                    stderr=subprocess.PIPE, timeout=300, env=environment)
    else:
        result = subprocess.run(command, capture_output=True, timeout=45, env=environment)
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
    verify_tag(repository, tag, commit, untagged_target=release.get('target_commitish'))


def verify_published_baseline(release):
    if (release.get('id') != int(BASELINE['release_id']) or release.get('tag_name') != BASELINE['tag']
            or release.get('draft') is not False):
        raise ValueError('Expected the exact published upgrade predecessor')
    verify_tag(BASELINE['repository'], BASELINE['tag'], BASELINE['source_commit'])
    for pin in BASELINE['assets'].values():
        asset = asset_identity(release, pin['name'], pin['sha256'])
        if asset['bytes'] != pin['bytes']:
            raise ValueError('Unexpected pinned published archive size')


def verify_tag(repository, tag, commit, *, untagged_target=None):
    reference = gh_get(f'repos/{repository}/git/ref/tags/{tag}', missing_ok=True)
    if reference is None:
        if untagged_target != commit:
            raise ValueError('An untagged draft must name the full frozen commit as target_commitish')
        return
    target = reference['object']
    for _ in range(8):
        if target['type'] != 'tag':
            break
        oid = pinned(target['sha'], r'[0-9a-f]{40}', 'annotated tag SHA')
        target = gh_get(f'repos/{repository}/git/tags/{oid}')['object']
    if target['type'] != 'commit' or target['sha'] != commit:
        raise ValueError('Release tag does not resolve to the pinned commit')


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
        if release.get('draft') is False and all(
            value == BASELINE[key] for key,value in (('repository',repository),('release_id',release_id),
                                                      ('tag',tag),('source_commit',commit))
        ):
            verify_published_baseline(release)
            if any(pin['name'] != BASELINE['assets'][role]['name']
                   or pin['sha256'] != BASELINE['assets'][role]['sha256'] for role,pin in records.items()):
                raise ValueError('Published predecessor requires the fixed Windows archive pins')
        else:
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
                                      'download_identity':'operator-resolved capabilities' if capabilities else 'runner release API'})


def fetch_baseline(work):
    candidate = read_json(work/'downloads.json')
    repository = BASELINE['repository']
    if (candidate['tag'] != FINAL_TAG or candidate['repository'] != repository
            or candidate['source_commit'] == BASELINE['source_commit']
            or not os.environ.get('GH_TOKEN')):
        raise ValueError('Baseline fetch requires the final candidate and built-in runner token')
    release_id, tag = BASELINE['release_id'], BASELINE['tag']
    release = gh_get(f'repos/{repository}/releases/{release_id}')
    verify_published_baseline(release)
    for role, pin in BASELINE['assets'].items():
        asset = asset_identity(release, pin['name'], pin['sha256'])
        archive = work/f'baseline-{role}.zip'
        gh_get(f'repos/{repository}/releases/assets/{asset["id"]}', 'application/octet-stream', archive)
        if archive.stat().st_size != pin['bytes'] or sha256(archive) != pin['sha256']:
            raise ValueError(f'Published {role} archive differs from its fixed pin')
    print(f'Pinned public predecessor {tag} ({BASELINE["source_commit"]}) verified', flush=True)


def verify_manifest(manifest, role, tag, commit, asset_name):
    batch = pinned(manifest.get('test_batch',''), r'[A-Za-z0-9-]{1,40}', 'package batch')
    if tag == FINAL_TAG and batch != FINAL_BATCH:
        raise ValueError('Final package must use the frozen release batch')
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
    if role == 'game' or tag == FINAL_TAG:
        if ((role == 'game' and manifest.get('public_game_feedback') is not True)
                or manifest.get('community_feedback_enabled') is not False
                or manifest.get('feedback_default_source') != 'external_player' or manifest.get('feedback_source_batch') != batch
                or manifest.get('feedback_endpoint') != PUBLIC_ORIGIN+'/v1'
                or manifest.get('privacy_url') != PUBLIC_ORIGIN+'/privacy-player.html'):
            raise ValueError(f'{role} package lacks the online player feedback identity')
        if role == 'test':
            if (manifest.get('public_test_feedback') is not True or manifest.get('offline_feedback') is not True
                    or 'public_game_feedback' in manifest):
                raise ValueError('Final Test must declare online player feedback and offline capture')
        elif manifest.get('public_test_feedback') or manifest.get('offline_feedback'):
            raise ValueError('Game must retain the Game feedback and save profile')
    elif set(manifest) & {'feedback_endpoint','privacy_url','feedback_default_source','feedback_source_batch',
                          'public_game_feedback','community_feedback_enabled','public_test_feedback'}:
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


def verify_firewall_coverage(family, addresses):
    version = 4 if family=='IPv4' else 6
    networks = []
    if not isinstance(addresses,list) or not addresses:
        raise ValueError(f'Missing active {family} firewall address filter')
    for address in addresses:
        if not isinstance(address,str):
            raise ValueError(f'Invalid active {family} firewall address filter')
        if '-' in address:
            first,last=map(str.strip,address.split('-',1))
            networks.extend(ipaddress.summarize_address_range(ipaddress.ip_address(first),ipaddress.ip_address(last)))
        else:
            networks.append(ipaddress.ip_network(address.strip(),strict=False))
    expected = ipaddress.collapse_addresses(map(ipaddress.ip_network,BLOCKED_PREFIXES[family]))
    if any(network.version!=version for network in networks) or set(ipaddress.collapse_addresses(networks))!=set(expected):
        raise ValueError(f'Active {family} firewall filter differs from the required address coverage')


@contextmanager
def guarded_binary(binary, role):
    rule = f'VNBReleaseQA-{role}-' + uuid.uuid4().hex
    command = ['powershell.exe','-NoProfile','-NonInteractive','-File',str(SCRIPTS/'windows-release-firewall.ps1')]
    rules=[]
    try:
        for family, prefixes in BLOCKED_PREFIXES.items():
            options=['-Rule',rule,'-Program',str(binary),'-Family',family,'-AddressCsv',','.join(prefixes)]
            rules.append(options)
            installed=subprocess.run(command+['-Operation','Install']+options,check=True,timeout=60,
                                     stdout=subprocess.PIPE,text=True)
            verify_firewall_coverage(family,json.loads(installed.stdout))
        print(f'Windows QA {role}: active IPv4 non-loopback and all IPv6 outbound blocks verified',flush=True)
        yield
    finally:
        cleanup_failure=None
        for options in reversed(rules):
            try:
                subprocess.run(command+['-Operation','Remove']+options,check=True,timeout=60)
            except (subprocess.CalledProcessError,subprocess.TimeoutExpired) as error:
                cleanup_failure=error
        if cleanup_failure:
            raise RuntimeError(f'Failed to remove a {role} firewall rule from the disposable runner') from cleanup_failure


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
    main_scene = '' if scene is None else '\nrun/main_scene='+json.dumps(scene.as_posix(),ensure_ascii=False)
    config = ('[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='
              +json.dumps(expected['qa_dir'],ensure_ascii=False)+main_scene
              +'\nfeedback_endpoint='+json.dumps(endpoint)+'\nfeedback_privacy_url=""\nfeedback_source_batch="HostedWindowsReleaseQA"'
              +'\n\n[windows_release_qa]\nconfiguration='+json.dumps(json.dumps(data,ensure_ascii=False),ensure_ascii=False)+'\n')
    path.write_text(config,encoding='utf-8')


def phase_diagnostics(text):
    lines = []
    for line in text.splitlines():
        line = line.strip()
        if not line.startswith(('Godot Engine v','VNB_WINDOWS_QA:','SCRIPT ERROR:','ERROR:','FAIL:','at:','[0]','[1]')):
            continue
        line = re.sub(r'https?://[^\s"<>]+','[redacted URL]',line,flags=re.I)
        line = re.sub(r'\b(?:Bearer|Basic)\s+[A-Za-z0-9_.+/=-]+','[redacted authorization]',line,flags=re.I)
        line = re.sub(r'\b(?:client_id|deletion_token|gh_token|authorization|sig)\b["\']?\s*[:=]\s*["\']?[^\s,"\'}]+',
                      '[redacted credential]',line,flags=re.I)
        if line not in lines:
            lines.append(line)
    return '\n'.join(lines[-30:])


def verify_phase(binary, scene, profile_dir, work, expected, endpoint, phase, env):
    override=binary.parent/'override.cfg'
    if override.exists():
        raise ValueError('Unexpected executable override before launch')
    log=work/(phase+'.engine.log')
    write_override(override,scene,profile_dir,work,expected,endpoint,phase)
    def collect(stdout,stderr):
        text=''.join(value.decode('utf-8',errors='replace') if isinstance(value,bytes) else value or ''
                     for value in (stdout,stderr))
        (work/(phase+'.log')).write_text(text,encoding='utf-8')
        if log.exists():
            text+='\n'+log.read_text(encoding='utf-8',errors='replace')
        return text

    try:
        print(f'Windows QA {expected["edition"]}: starting {phase} in the isolated profile',flush=True)
        try:
            arguments = [str(binary),'--headless','--log-file',str(log),'--',
                         '--enable-playtest-feedback','--playtest-source=automated']
            if expected.get('display_version') == FINAL_TAG[1:]:
                arguments.append('--enable-playtest-telemetry')
            process=subprocess.run(arguments,
                                   cwd=binary.parent,env=env,capture_output=True,text=True,encoding='utf-8',
                                   errors='replace',timeout=90)
        except subprocess.TimeoutExpired as error:
            print(phase_diagnostics(collect(error.stdout,error.stderr)),flush=True)
            raise RuntimeError(f'{expected["edition"]} {phase} timed out') from None
    finally:
        override.unlink(missing_ok=True)
    stdout=collect(process.stdout,process.stderr)
    errors=[line for line in stdout.splitlines() if 'ERROR:' in line and 'root certificate store' not in line]
    if process.returncode or errors or f'PASS: Windows release {phase}' not in stdout:
        print(phase_diagnostics(stdout),flush=True)
        raise RuntimeError(f'{expected["edition"]} {phase} failed (exit {process.returncode})')
    report=read_json(work/(phase+'.json'))
    if (report.get('passed') is not True or report.get('phase')!=phase
            or Path(report['user_dir']).resolve()!=profile_dir.resolve()):
        raise ValueError('Runtime receipt does not match the isolated package and phase')
    return report


def verify_startup(binary, stage, profile, expected, env, *, windowed=False):
    """Run the packaged main scene, preserving its own startup and hub transition."""
    override = binary.parent/'override.cfg'
    if override.exists():
        raise ValueError('Unexpected executable override before startup')
    log = stage/'startup.engine.log'
    write_override(override, None, profile, stage, expected, '', 'startup')
    try:
        try:
            launch = [str(binary), '--verbose', '--quit-after', '180', '--log-file', str(log)]
            if windowed:
                launch.extend(('--audio-driver','Dummy'))
            else:
                launch.insert(1, '--headless')
            process = subprocess.run(launch, cwd=binary.parent, env=env,
                                     capture_output=True, text=True, encoding='utf-8',
                                     errors='replace', timeout=45)
        except subprocess.TimeoutExpired as error:
            output = (error.stdout or b'').decode('utf-8', errors='replace')
            output += (error.stderr or b'').decode('utf-8', errors='replace')
            print(phase_diagnostics(output), flush=True)
            raise RuntimeError(f'{expected["edition"]} shipped startup timed out') from None
    finally:
        override.unlink(missing_ok=True)
    output = process.stdout + process.stderr
    if log.exists():
        output += '\n' + log.read_text(encoding='utf-8', errors='replace')
    (stage/'startup.log').write_text(output, encoding='utf-8')
    def loaded(scene):
        return re.search(r'Loading resource: res://(?:src/ui/'+scene+r'\.tscn\b|'
                         r'\.godot/exported/\d+/export-[0-9a-f]+-'+scene+r'\.scn\b)',output)

    if windowed and not loaded('startup') and re.search(
            r'OpenGL.*(?:not supported|does not support|could not|failed|require)|'
            r'(?:failed|unable|cannot|could not).*?(?:OpenGL|WGL|display driver|create window)|'
            r'Your video card driver does not support', output, re.IGNORECASE):
        print(phase_diagnostics(output), flush=True)
        return 'windowed unavailable: runner display or graphics initialization failed'
    if (process.returncode or any('ERROR:' in line and 'root certificate store' not in line
                                  for line in output.splitlines())
            or not loaded('startup') or (not windowed and not loaded('prototype_hub'))):
        print(phase_diagnostics(output), flush=True)
        raise RuntimeError(f'{expected["edition"]} shipped startup did not reach the laboratory'
                           if not windowed else f'{expected["edition"]} shipped windowed startup failed')
    if windowed:
        if not re.search(r'OpenGL (?:API|ES)|Vulkan API|Direct3D', output):
            raise RuntimeError(f'{expected["edition"]} windowed startup did not identify a rendering backend')
        return 'windowed startup and renderer initialized'
    return 'shipped startup reached the laboratory (headless)'


def windows_host_facts(binary, env):
    command = (
        "$ErrorActionPreference='Stop'; "
        "$s=Get-AuthenticodeSignature -LiteralPath $env:VNB_QA_EXE; "
        "$id=[System.Diagnostics.Process]::GetCurrentProcess().SessionId; "
        "[pscustomobject]@{status=$s.Status.ToString(); signer_present=($null -ne $s.SignerCertificate); "
        "interactive=([Environment]::UserInteractive -and $id -ne 0)} | ConvertTo-Json -Compress"
    )
    result = subprocess.run(['powershell.exe','-NoProfile','-NonInteractive','-Command',command],
                            check=True, timeout=45, capture_output=True, text=True, encoding='utf-8',
                            env=env | {'VNB_QA_EXE':str(binary)})
    facts = json.loads(result.stdout)
    pinned(facts['status'], r'[A-Za-z]+', 'Authenticode status')
    if any(type(facts[key]) is not bool for key in ('signer_present','interactive')):
        raise ValueError('Missing Windows runner or Authenticode evidence')
    return facts


def verify_fresh_startup(binary, stage, expected):
    stage.mkdir()
    env = runner_environment(stage/'runtime')
    facts = windows_host_facts(binary, env)
    profile = Path(env['APPDATA'])/expected['qa_dir']
    if profile.exists():
        raise ValueError('Fresh Windows startup requires an unused profile')
    role = expected['edition']
    print(f'Windows QA {role}: Authenticode {facts["status"]}, signer present: {facts["signer_present"]}', flush=True)
    headless = verify_startup(binary,stage,profile,expected,env)
    windowed = 'windowed skipped: Windows runner session has no interactive desktop'
    if facts['interactive']:
        window_stage = stage/'windowed'
        window_stage.mkdir()
        window_env = runner_environment(window_stage/'runtime')
        window_profile = Path(window_env['APPDATA'])/expected['qa_dir']
        if window_profile.exists():
            raise ValueError('Fresh Windows windowed startup requires an unused profile')
        windowed = verify_startup(binary,window_stage,window_profile,expected,window_env,windowed=True)
    print(f'Windows QA {role}: fresh profile {headless}. {windowed}.', flush=True)
    return {'authenticode_status':facts['status'], 'signer_present':facts['signer_present'],
            'headless':headless, 'windowed':windowed}


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


def verify_delivery(database, receipt, manifest, *, automatic=False):
    with closing(sqlite3.connect(database)) as data:
        rows = data.execute('SELECT id,kind,body,client_id FROM events').fetchall()
    event_id = pinned(receipt['feedback_id'], r'[0-9a-f]{64}', 'opinion receipt ID')
    pins = {event_id: ('feedback', {'note': NOTE,'sharing_mode': 'opinion'})}
    if automatic:
        auto_id = pinned(receipt['automatic_id'], r'[0-9a-f]{64}', 'automatic event receipt ID')
        if auto_id == event_id or not receipt.get('automatic_visit_id'):
            raise ValueError('Manual and automatic delivery require separate attributed events')
        pins[auto_id] = ('event', {'event':'visit_summary', 'visit_id':receipt['automatic_visit_id'],
                                   'sharing_mode':'basic'})
    if (len(rows) != len(pins) or {row[0]:row[1] for row in rows} != {key:pin[0] for key,pin in pins.items()}
            or len({row[3] for row in rows}) != 1):
        raise ValueError('Unexpected or duplicate synthetic records in the loopback receiver')
    expected={'chapter_id':'hardware_foundations','level_id':'tutorial','mode':manifest['edition'],'source':'automated',
              'source_batch':'HostedWindowsReleaseQA','build_version':manifest['display_version'],
              'source_commit':manifest['source_commit'],'test_batch':manifest['test_batch']}
    forbidden = {'program_source','examples','output','intent','work','client_id','deletion_token'}
    for row_id, kind, body, _ in rows:
        payload = json.loads(body)['payload']
        required = expected | pins[row_id][1]
        if (any(payload.get(key) != value for key,value in required.items())
                or forbidden & payload.keys() or (kind == 'event' and 'note' in payload)
                or not all(payload.get(key) for key in ('consent_version','privacy_notice_version','consent_timestamp'))):
            raise ValueError('Synthetic loopback record has incorrect attribution, missing consent, or protected work')
    if automatic:
        report_dir = database.parent/'private-report'
        subprocess.run([sys.executable,str(ROOT/'server/private_report.py'),'--database',str(database),
                        '--output',str(report_dir)], check=True, timeout=30)
        report = read_json(report_dir/'report.json')
        opinions = report['received_feedback']
        if (report['deduplicated_events'] != len(rows) or report['quarantined_records'] or len(opinions) != 1
                or opinions[0]['event_id'] != event_id or opinions[0]['note'] != NOTE
                or opinions[0]['mode'] != manifest['edition']):
            raise ValueError('Private report disagrees with the synthetic native receiver')
    return {'opinions':1, 'automatic_events':int(automatic)}


def phase_pair(first, second, *preserved):
    if first['pid'] == second['pid'] or any(first[key] != second[key] for key in preserved):
        raise ValueError('Independent Windows process did not preserve the synthetic state')


def verify_offline_bundle(stage, case_id, manifest):
    with zipfile.ZipFile(stage/'offline-feedback.zip') as bundle:
        prefix = f'cases/{pinned(case_id, r"[0-9a-f]{32}", "offline case ID")}/'
        index = json.loads(bundle.read('manifest.json'))
        build = index['build']
        case = json.loads(bundle.read(prefix+'case.json'))
        notes = bundle.read(prefix+'notes.jsonl').decode('utf-8').splitlines()
        if (not notes or json.loads(notes[-1])['note'] != NOTE or case.get('note') != NOTE
                or case.get('task',{}).get('level_id') != 'tutorial'
                or index.get('format') != 'vnb-offline-playtest' or index.get('case_count') != 1
                or build.get('source_commit') != manifest['source_commit']
                or build.get('version') != manifest['display_version']):
            raise ValueError('Offline ZIP does not preserve the restarted note')
        inventory = {entry['path']:entry for entry in index['files']}
        member_names = bundle.namelist()
        if (len(index['files']) != len(inventory) or len(member_names) != len(inventory)+1
                or set(member_names) != inventory.keys() | {'manifest.json'}
                or any(Path(name).name == 'feedback_outbox_v1.json' for name in inventory)):
            raise ValueError('Offline ZIP inventory contains unexpected content')
        for name, entry in inventory.items():
            data = bundle.read(name)
            if len(data) != entry['size'] or hashlib.sha256(data).hexdigest() != entry['sha256']:
                raise ValueError('Offline ZIP inventory hash mismatch')


@contextmanager
def disconnected_endpoint():
    with socket.socket() as reservation:
        reservation.setsockopt(socket.SOL_SOCKET, socket.SO_EXCLUSIVEADDRUSE, 1)
        reservation.bind(('127.0.0.1', 0))
        port = reservation.getsockname()[1]
        yield port, f'http://127.0.0.1:{port}'


def phase_identity(manifest, qa_dir):
    expected = {key:manifest[key] for key in ('edition','display_version','source_commit','test_batch',
                                             'build_id','save_profile','engine')}
    return expected | {'qa_dir':qa_dir}


def verify_unchanged(binary, manifest, archive, digest):
    if (any(sha256(binary.parent/name)!=value for name,value in manifest['files_sha256'].items())
            or read_json(binary.parent/'BUILD-MANIFEST.json') != manifest
            or sha256(archive)!=digest or (binary.parent/'override.cfg').exists()):
        raise ValueError('Frozen archive or extracted package changed during Windows QA')


def verify_upgrade(binary, expected, baseline, scene, stage):
    stage.mkdir()
    old_binary, old_manifest = baseline
    role = expected['edition']
    if old_manifest['save_profile'] != expected['save_profile']:
        raise ValueError('The predecessor and candidate must use the same edition save profile')
    if not old_binary.with_suffix('.pck').exists():
        PACKAGE.embedded_pck_sha256(old_binary)
    env = runner_environment(stage/'runtime')
    profile = Path(env['APPDATA'])/expected['qa_dir']
    with guarded_binary(old_binary, role):
        first = verify_phase(old_binary,scene,profile,stage,phase_identity(old_manifest,expected['qa_dir']),'','seed',env)
    # The candidate firewall is already active. The shipped main scene and the
    # headless save loader both see the same old-build profile before any rewrite.
    startup = verify_startup(binary, stage, profile, expected, env)
    second = verify_phase(binary,scene,profile,stage,expected,'','upgrade',env)
    phase_pair(first, second, 'workbench_sha256', 'save_sha256')
    print(f'Windows QA {role}: previous-build saves reopened with matching hashes', flush=True)
    return {'previous_build':old_manifest['build_id'],'startup':startup,
            'seed':first,'upgrade':second}


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
    final = identity['tag'] == FINAL_TAG
    prepared = {}
    baseline = {}
    for role in ('game','test'):
        stage=work/role
        stage.mkdir()
        prepared[role]=unpack(work/(role+'.zip'),stage/'copy',role,identity)
        if final:
            baseline[role]=unpack(work/f'baseline-{role}.zip',stage/'baseline-package',role,BASELINE)
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
        expected=phase_identity(manifest,qa_dir)
        details = {}
        try:
            with guarded_binary(binary,role):
                if final:
                    details['fresh_startup'] = verify_fresh_startup(binary,stage/'first-launch',expected)
                    details['compatibility'] = verify_upgrade(binary,expected,baseline[role],scene,stage/'upgrade')
                if role == 'game' or final:
                    with disconnected_endpoint() as (port, endpoint):
                        first=verify_phase(binary,scene,profile_dir,stage,expected,endpoint,'write',env)
                    with receiver(stage,port) as database:
                        second=verify_phase(binary,scene,profile_dir,stage,expected,endpoint,'restart',env)
                        details['delivery'] = verify_delivery(database,second,manifest,automatic=final)
                    print(f'Windows QA {role}: verified SQLite counts {details["delivery"]}', flush=True)
                else:
                    first=verify_phase(binary,scene,profile_dir,stage,expected,'','write',env)
                    second=verify_phase(binary,scene,profile_dir,stage,expected,'','restart',env)
                    verify_offline_bundle(stage,first['feedback_id'],manifest)
                if final and role == 'test':
                    offline = stage/'disconnected'
                    offline.mkdir()
                    offline_env = runner_environment(offline/'runtime')
                    offline_profile = Path(offline_env['APPDATA'])/qa_dir
                    with disconnected_endpoint() as (_, endpoint):
                        capture = verify_phase(binary,scene,offline_profile,offline,expected,endpoint,'capture',offline_env)
                        export = verify_phase(binary,scene,offline_profile,offline,expected,endpoint,'export',offline_env)
                    phase_pair(capture, export, 'workbench_sha256', 'feedback_id')
                    verify_offline_bundle(offline,capture['feedback_id'],manifest)
                    details['disconnected'] = {'capture':capture,'export':export}
                    print('Windows QA test: disconnected capture and restarted offline ZIP verified', flush=True)
        finally:
            if any(path.exists() for path in protected):
                raise RuntimeError('A package created files in an unisolated Godot player path')
        phase_pair(first, second, 'workbench_sha256', 'feedback_id')
        verify_unchanged(binary,manifest,work/(role+'.zip'),identity['assets'][role]['sha256'])
        if final:
            verify_unchanged(*baseline[role],work/f'baseline-{role}.zip',BASELINE['assets'][role]['sha256'])
        write_json(stage/'result.json',{'passed':True,'asset':identity['assets'][role],
                   'build_id':manifest['build_id'],'edition':role,'write':first,'restart':second,**details})
        print(f'PASS: {role} frozen Windows executable, isolated save/restart and synthetic feedback '
              f'(ZIP SHA-256 {identity["assets"][role]["sha256"]})',flush=True)
    write_json(work/'result.json',{'passed':True, **identity,'scope':'Windows hosted headless binary; synthetic local feedback only'})


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('phase',choices=('fetch','fetch-baseline','verify'))
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
    elif args.phase=='fetch-baseline':
        fetch_baseline(work)
    else:
        verify(work)


if __name__=='__main__':
    main()

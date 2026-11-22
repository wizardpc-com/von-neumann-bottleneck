#!/usr/bin/env python3
"""Build both free candidates from one committed Git archive, never live player data."""
import argparse,datetime,hashlib,io,ipaddress,json,os,re,shutil,stat,subprocess,sys,tarfile,zipfile,importlib.util
from urllib.parse import urlsplit
from pathlib import Path


NETWORK_FEEDBACK_ORIGIN = "https://feedback.yanruiqing.com:8443"
PLAYER_PRIVACY_URL = NETWORK_FEEDBACK_ORIGIN + '/privacy-player.html'
PLAYER_PILOT_PROFILE = 'EditionTestPilot'
PLAYER_PILOT_BATCH = 'PlayerFeedbackPilot'
OFFLINE_SCREENSHOT_DIRECTORY = 'docs/verification/20261019-team-closeout/screenshots'


def package_files(folder):
    return [path for path in sorted(folder.rglob('*')) if path.is_file() or path.is_symlink()]


def packaged_bytes(path):
    return os.readlink(path).encode('utf-8') if path.is_symlink() else path.read_bytes()


def godot_path_literal(path):
    return json.dumps(path.resolve().as_posix(),ensure_ascii=False)


def candidate_scoped_settings(source, creation_journey=False):
    """Let export flags, not the source/F5 override, select 40/51/60 tasks."""
    # Full current journeys also use this setting for their earned final CG.
    # Preserve the existing sixty-task presentation contract verbatim.
    if creation_journey:
        return source
    section = ''
    lines = []
    for line in source.splitlines(keepends=True):
        stripped = line.strip()
        if stripped.startswith('[') and stripped.endswith(']'):
            section = stripped[1:-1]
        if section == 'game' and stripped.split('=', 1)[0].strip() == 'full_journey':
            line = 'full_journey=false\n'
        lines.append(line)
    return ''.join(lines)


def offline_profile(profile):
    return isinstance(profile,str) and len(profile)<=40 and re.fullmatch(r'OfflineTeammate(?:-[A-Za-z0-9-]+)?',profile) is not None


def offline_readme(source,profile):
    if not offline_profile(profile):raise ValueError('Invalid offline tester profile')
    return source.replace('/OfflineTeammate/','/'+profile+'/')


def package_offline_screenshots(project, folder):
    source=project/OFFLINE_SCREENSHOT_DIRECTORY
    destination=folder/'screenshots';destination.mkdir()
    for name in ['lab-home.png','task-map.png','hardware.png','feedback.png']:
        shutil.copy2(source/name,destination/name)


def public_https_url(value, api_root=False):
    if any(ord(char)<32 for char in value) or (not api_root and len(value)>2048):
        return False
    try:
        url=urlsplit(value)
        port=url.port
        host=url.hostname or ''
    except ValueError:
        return False
    try:ipaddress.ip_address(host)
    except ValueError:pass
    else:return False
    if (url.scheme!='https' or not host or port not in (None,443) or url.username or url.password
            or url.query or url.fragment or host.endswith(('.local','.localhost','.test','.invalid','.example'))
            or not re.fullmatch(r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}',host)):
        return False
    path=r'' if api_root else r'(?:/[A-Za-z0-9._~/-]*)?'
    return re.fullmatch(r'https://[a-z0-9.-]+(?::443)?'+path,value) is not None


def player_pilot_batch(batch):
    return len(batch) <= 40 and re.fullmatch(PLAYER_PILOT_BATCH + r'(?:-[A-Za-z0-9][A-Za-z0-9-]*)?', batch) is not None


def write_zip_entry(package, path, relative):
    if path.is_symlink():
        entry=zipfile.ZipInfo(relative.as_posix())
        entry.create_system=3
        entry.external_attr=(stat.S_IFLNK | 0o777) << 16
        package.writestr(entry,packaged_bytes(path))
    else:
        entry=zipfile.ZipInfo.from_file(path,relative.as_posix())
        if len(relative.parts)>=5 and relative.parts[0]=='macOS' and relative.parts[1].endswith('.app') and relative.parts[2:4]==('Contents','MacOS'):
            entry.create_system=3
            entry.external_attr=(stat.S_IFREG | 0o755) << 16
        entry.compress_type=zipfile.ZIP_DEFLATED
        with path.open('rb') as source, package.open(entry,'w') as destination:
            shutil.copyfileobj(source,destination)

def edition_identity(edition, version, commit, batch, network_feedback=False, player_pilot=False, player_release=False):
    """One source identity, two fixed access policies and disjoint stable profiles."""
    if edition not in ('game', 'test') or not re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?', version):
        raise ValueError('Edition needs game/test and a semantic release version')
    if not re.fullmatch(r'[0-9a-f]{40}', commit) or not re.fullmatch(r'[A-Za-z0-9-]{1,40}', batch or ''):
        raise ValueError('Edition needs a full commit SHA and an explicit immutable batch')
    if network_feedback and edition != 'test':
        raise ValueError('Network feedback acceptance requires Test Edition')
    profile = 'EditionGame' if edition == 'game' else 'EditionTest'
    if network_feedback:
        profile = 'EditionTestFeedback'
    build_lane = 'test-feedback' if network_feedback else edition
    if player_pilot:
        if edition != 'test' or network_feedback or not player_pilot_batch(batch):
            raise ValueError('Player feedback pilot requires Test Edition and a pilot batch')
        profile = PLAYER_PILOT_PROFILE
        build_lane = 'test-pilot'
    if player_release:
        if network_feedback or player_pilot or batch == 'unspecified':
            raise ValueError('Player release needs its own explicit batch and cannot use a QA lane')
        build_lane = edition + '-release'
    return {'edition': edition, 'edition_name': edition.title() + ' Edition',
            'release_version': version, 'display_version': version[1:],
            'build_id': 'vnb-' + build_lane + '-' + version + '-' + batch + '-' + commit[:12],
            'source_commit': commit, 'test_batch': batch, 'save_profile': profile,
            'save_directories': ['VonNeumannBottleneckCandidates/' + domain + '/' + profile
                                 for domain in ('representation', 'service')],
            'content_version': 'tasks-20261013-journey-v1', 'content_count': 60,
            'access_policy': 'earned' if edition == 'game' else 'all-task-entrances',
            'mode_locked': True, 'save_migration': False}


def edition_notes(project, identity, details, filename, binary_name):
    text = (project / 'distribution' / filename).read_text(encoding='utf-8')
    replacements = {'@EDITION@': details['edition_name'], '@VERSION@': details['release_version'],
                    '@PROFILE@': details['save_profile'], '@BATCH@': details['test_batch'],
                    '@CONTENT_VERSION@': details['content_version'],
                    '@BINARY_NAME@': binary_name,
                    '@ACCESS_ZH@': ('按正常前置解锁；真实完成后记录成果。' if details['edition'] == 'game'
                                   else '全部任务入口可访问；进入不等于完成，不授予 Game 成果。'),
                    '@ACCESS_EN@': ('Normal prerequisites and earned completion.' if details['edition'] == 'game'
                                   else 'All task entrances are available. Entry is not completion and grants no Game achievements.')}
    for key, value in replacements.items():
        text = text.replace(key, value)
    if re.search(r'@[A-Z_]+@', text):
        raise ValueError('Unresolved edition note placeholder: ' + filename)
    return identity + text


def online_player_notes(notes, filename, feedback, *, pilot):
    dual_test = feedback.get('public_test_feedback', False)
    heading = ('Player feedback pilot / 真人试玩意见反馈' if pilot else
               'Test Edition player feedback / 测试版反馈' if dual_test else
               'Game Edition player feedback / 游戏版意见反馈')
    if filename == 'README.txt':
        offline = ('反馈保存在本机；可通过界面导出，只有你主动分享才会交给维护者。未配置在线接收端。\n'
                   'Feedback remains local and can be exported. Share it deliberately with the maintainer; no receiver is configured.')
        online = ('在任务内点反馈按钮或按 F8，填写意见后点「发送」。只在本机保存不会上传。\n'
                  'While in a task, use the feedback button or press F8, enter your opinion, and choose Send. Saving locally does not upload it.')
        if pilot:
            online += ('\n基础统计、详细统计及成绩分享沿用各自的同意选项，新存档默认关闭。\n'
                       'Basic statistics, detailed playtest data and score sharing retain their existing consent choices and start off on a fresh profile.')
        if dual_test:
            online += ('\n自动发送的统计须另行同意，新存档默认关闭。也可单独记录现场，离线保存截图、任务现场与备注；'
                       '通过「导出全部反馈」生成本地 ZIP，由你决定是否私下分享。\n'
                       'Automatic statistics require a separate opt-in and start off on a fresh profile. '
                       'You can also capture a local incident with a screenshot, task context, and a note. '
                       'Use Export All Feedback to create a local ZIP and share it privately if you choose.')
    elif filename == 'KNOWN-ISSUES.txt':
        offline = ('没有联网依赖，也没有配置在线反馈接收端。\n'
                   '  Rankings and challenges remeasure locally under the existing rules. They are not an authenticated online leaderboard. No network is required and no feedback receiver is configured.')
        receiver_note = 'Sending pilot opinions' if pilot else 'Sending opinions'
        online = ('离线游玩可用；发送试玩意见需要访问本批配置的接收端。\n'
                  '  Rankings and challenges remeasure locally under the existing rules. They are not an authenticated online leaderboard. '
                  f'{receiver_note} requires access to the configured receiver.')
    else:
        return notes + '\n' + heading + '\n'
    if offline not in notes:
        raise ValueError('Review changed edition feedback wording: ' + filename)
    return notes.replace(offline, online, 1) + (
        f'\n{heading}\n'
        f"Feedback receiver / 反馈接收端: {feedback['feedback_endpoint']}\n"
        f"Privacy notice / 隐私说明: {feedback['privacy_url']}\n"
    )


def offline_capture_notes(notes):
    offline = ('反馈保存在本机；可通过界面导出，只有你主动分享才会交给维护者。未配置在线接收端。\n'
               'Feedback remains local and can be exported. Share it deliberately with the maintainer; no receiver is configured.')
    if offline not in notes:
        raise ValueError('Review changed edition feedback wording: README.txt')
    return notes.replace(offline,
        '在任务内按 F8 或点「现场反馈」，可保存截图、任务现场与备注。结束时点「导出全部反馈」，将 ZIP 私下交给维护者。未配置在线接收端。\n'
        'In a task, press F8 or use Capture Feedback to save a screenshot, task context, and a note. Use Export All Feedback and share the ZIP privately with the maintainer. No receiver is configured.', 1)


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--godot',required=True);p.add_argument('--commit',default='HEAD')
    p.add_argument('--platform',choices=['both','macOS','Windows'],default='both')
    p.add_argument('--mac-template',type=Path,help='Project-private matching official macos.zip')
    p.add_argument('--second-act-profile',help='Stable isolated candidate profile on both platforms')
    p.add_argument('--windows-template',type=Path,help='Matching official Windows release x86_64 executable')
    p.add_argument('--test-batch',help='Immutable test batch identity (safe1–40 characters)')
    p.add_argument('--feedback-endpoint',default='',help='Approved HTTPS receiver base; empty keeps local-only delivery')
    p.add_argument('--local-feedback-test',action='store_true',help='Explicit local acceptance package; never external-ready')
    p.add_argument('--creation-journey',action='store_true',help='Include the C/P/G candidate in the isolated second-act journey')
    p.add_argument('--public-playtest',action='store_true',help='Prepare the explicit Windows public prerelease; external acceptance remains separate')
    p.add_argument('--offline-tester',action='store_true',help='Isolated Windows teammate build with all sixty task entrances available')
    p.add_argument('--release-version',default='',help='Public prerelease tag or edition semantic version, e.g. v0.6.0')
    p.add_argument('--edition',choices=['game','test'],help='Locked Game/Test edition with sixty tasks and its own stable save profile')
    p.add_argument('--privacy-url',default='',help='Published HTTPS privacy notice for the player release, prerelease, or pilot')
    feedback_lane = p.add_mutually_exclusive_group()
    feedback_lane.add_argument('--network-feedback-test', action='store_true',
                               help='Build a separate macOS Test Edition for restricted HTTPS acceptance')
    feedback_lane.add_argument('--player-feedback-pilot', action='store_true',
                               help='Build an isolated Test Edition for invited players with explicit receiver and privacy URLs')
    feedback_lane.add_argument('--player-release', action='store_true',
                               help='Prepare public Game and Test editions for separate release approval')
    a=p.parse_args()
    if a.network_feedback_test:
        if (a.edition != 'test' or a.platform != 'macOS' or a.feedback_endpoint or a.privacy_url
                or a.public_playtest or a.offline_tester or a.local_feedback_test):
            p.error('--network-feedback-test requires --edition test --platform macOS and its fixed VNB endpoint')
        a.feedback_endpoint = NETWORK_FEEDBACK_ORIGIN + '/v1'
        a.privacy_url = NETWORK_FEEDBACK_ORIGIN + '/privacy.html'
    if a.player_feedback_pilot:
        if a.edition != 'test' or a.public_playtest or a.offline_tester or a.local_feedback_test:
            p.error('--player-feedback-pilot requires --edition test and is separate from legacy feedback lanes')
        if a.test_batch is None:
            a.test_batch = PLAYER_PILOT_BATCH
        if not player_pilot_batch(a.test_batch):
            p.error('Use PlayerFeedbackPilot or PlayerFeedbackPilot-<wave> (up to 40 characters)')
        receiver_base = a.feedback_endpoint.removesuffix('/v1')
        if receiver_base != NETWORK_FEEDBACK_ORIGIN and not public_https_url(receiver_base, api_root=True):
            p.error('Player feedback pilot requires an explicit HTTPS receiver base (optional /v1)')
        if a.privacy_url != PLAYER_PRIVACY_URL and not public_https_url(a.privacy_url):
            p.error('Player feedback pilot requires an explicit public HTTPS player privacy notice')
    elif ((a.second_act_profile or '').casefold() == PLAYER_PILOT_PROFILE.casefold()
          or (a.test_batch or '').casefold().partition('-')[0] == PLAYER_PILOT_BATCH.casefold()):
        p.error('Player feedback pilot profile and batch are reserved for --player-feedback-pilot')
    edition_feedback = {}
    if a.network_feedback_test:
        edition_feedback = {'network_feedback_test': True, 'feedback_endpoint': a.feedback_endpoint,
                            'privacy_url': a.privacy_url}
    elif a.player_feedback_pilot:
        edition_feedback = {'player_feedback_pilot': True, 'feedback_endpoint': a.feedback_endpoint,
                            'privacy_url': a.privacy_url, 'feedback_default_source': 'external_player',
                            'feedback_source_batch': a.test_batch}
    dual_test = a.player_release and a.edition == 'test' and a.release_version == 'v0.6.1-playtest.2'
    if a.player_release:
        if a.edition not in ('game', 'test') or a.public_playtest or a.offline_tester or a.local_feedback_test:
            p.error('--player-release requires --edition game or test and cannot use a legacy feedback lane')
        if a.edition == 'game' or dual_test:
            if (a.feedback_endpoint, a.privacy_url) != (NETWORK_FEEDBACK_ORIGIN + '/v1', PLAYER_PRIVACY_URL):
                p.error('Online player releases require the exact VNB /v1 receiver and /privacy-player.html notice on HTTPS port 8443')
            edition_feedback = {'feedback_endpoint': a.feedback_endpoint, 'privacy_url': a.privacy_url,
                                'feedback_default_source': 'external_player', 'feedback_source_batch': a.test_batch,
                                'community_feedback_enabled': False}
            if dual_test:
                edition_feedback.update(public_test_feedback=True, offline_feedback=True)
            else:
                edition_feedback['public_game_feedback'] = True
        elif a.feedback_endpoint or a.privacy_url:
            p.error('Player release Test uses offline capture and accepts no receiver or privacy URL')
    edition = None
    if a.edition:
        if not edition_feedback and (a.public_playtest or a.offline_tester or a.local_feedback_test or a.feedback_endpoint or a.privacy_url):
            p.error('--edition is an offline product build, incompatible with legacy public/offline tester switches')
        try: edition = edition_identity(a.edition, a.release_version, a.commit, a.test_batch,
                                        a.network_feedback_test, a.player_feedback_pilot, a.player_release)
        except ValueError as error: p.error(str(error))
        if a.player_release:
            edition['player_release'] = True
        if a.second_act_profile and a.second_act_profile != edition['save_profile']:
            p.error('Edition profile is fixed: ' + edition['save_profile'])
        a.second_act_profile = edition['save_profile']
        a.creation_journey = True
    if a.mac_template and (not a.mac_template.is_file() or a.platform=='Windows'):p.error('--mac-template requires an existing macos.zip and Mac export')
    if a.second_act_profile is not None and (not re.fullmatch(r'[A-Za-z0-9-]{1,40}',a.second_act_profile)):p.error('--second-act-profile requires a safe1–40 character profile')
    if a.creation_journey and not a.second_act_profile:p.error('--creation-journey requires --second-act-profile')
    if a.test_batch and not re.fullmatch(r'[A-Za-z0-9-]{1,40}',a.test_batch):p.error('unsafe test batch')
    if a.windows_template and (not a.windows_template.is_file() or a.platform=='macOS'):p.error('Windows template requires Windows export and an existing file')
    url=urlsplit(a.feedback_endpoint)
    if a.feedback_endpoint and (url.scheme!='https' and not (a.local_feedback_test and url.scheme=='http' and url.hostname in ['127.0.0.1','localhost'])):p.error('HTTPS required except explicit local acceptance')
    if a.feedback_endpoint and (not url.hostname or url.username or url.password or url.query or url.fragment or a.feedback_endpoint.endswith('/')):p.error('unsafe receiver URL')
    if a.local_feedback_test and (not a.feedback_endpoint or url.hostname not in ['127.0.0.1','localhost']):p.error('local acceptance needs an explicit loopback endpoint')
    if a.public_playtest:
        if a.platform!='Windows' or a.local_feedback_test or a.mac_template:p.error('public playtest requires Windows only, without local acceptance or Mac template')
        if a.second_act_profile!='CloudPlaytest' or not a.creation_journey:p.error('public playtest requires the full CloudPlaytest journey')
        if a.release_version!='v0.5.0-alpha.2' or not a.test_batch or not re.fullmatch(r'[0-9a-f]{40}',a.commit):p.error('public playtest requires v0.5.0-alpha.2, a batch and a full fixed commit SHA')
        if not a.windows_template:p.error('public playtest requires a matching Windows template')
        if not public_https_url(a.feedback_endpoint,api_root=True) or not public_https_url(a.privacy_url):p.error('public playtest requires public HTTPS API-root and privacy-page URLs')
    elif (a.release_version and not a.edition) or (a.privacy_url and not edition_feedback):p.error('release version and privacy URL require --public-playtest')
    if a.offline_tester:
        if a.platform!='Windows' or a.public_playtest or a.local_feedback_test or a.feedback_endpoint or a.mac_template:
            p.error('offline tester requires Windows only, with no receiver or public mode')
        if not offline_profile(a.second_act_profile) or not a.creation_journey:
            p.error('offline tester requires the full OfflineTeammate or OfflineTeammate-<suffix> journey')
        if not a.test_batch or not re.fullmatch(r'[0-9a-f]{40}',a.commit) or not a.windows_template:
            p.error('offline tester requires a batch, fixed commit and Windows template')
    template=a.mac_template.resolve() if a.mac_template else None
    root=Path(__file__).resolve().parents[1]
    commit=subprocess.check_output(['git','rev-parse',a.commit],cwd=root,text=True,encoding='utf-8').strip()
    engine=subprocess.check_output([a.godot,'--version'],text=True,encoding='utf-8').strip()
    if not engine.startswith('4.7.1.stable.'):p.error('Godot 4.7.1 stable required')
    stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')+'-'+commit[:8]+('-'+a.edition if a.edition else '')
    work=root/'.godot/candidates'/stamp;project=work/'project';project.mkdir(parents=True)
    archive=subprocess.check_output(['git','archive',commit],cwd=root)
    with tarfile.open(fileobj=io.BytesIO(archive)) as source:
        selected = []
        for member in source.getmembers():
            dest=(project/member.name).resolve()
            if not dest.is_relative_to(project.resolve()) or not (member.isfile() or member.isdir()):raise ValueError('Unsupported archive member: '+member.name)
            if member.name.startswith('docs/verification/'):
                if not (a.offline_tester and member.name.startswith(OFFLINE_SCREENSHOT_DIRECTORY + '/')):
                    continue
            selected.append(member)
        source.extractall(project, members=selected)
    build_id=edition['build_id'] if edition else ('playtest-'+a.test_batch+'-' if a.test_batch else 'free-alpha-')+commit[:12]
    output=root/'build'/build_id
    if output.exists(): raise ValueError('Candidate already exists; never overwrite a frozen identity: '+build_id)
    output.mkdir(parents=True)
    spec=importlib.util.spec_from_file_location('branding',project/'scripts/check-branding.py')
    branding=importlib.util.module_from_spec(spec);spec.loader.exec_module(branding)
    brand=branding.read_brand(project)
    original=candidate_scoped_settings((project/'project.godot').read_text(encoding='utf-8'), a.creation_journey)
    original=re.sub(r'config/icon="[^"]*"','config/icon="'+brand['app_icon']+'"',original)
    presets=(project/'export_presets.cfg').read_text(encoding='utf-8')
    presets=presets.replace('exclude_filter="', 'exclude_filter="assets/branding/brand-review.*,' )
    if edition:
        presets=presets.replace('custom_features="free_candidate"', 'custom_features="free_candidate,'+a.edition+'_edition"')
        bundle_suffix = 'test.pilot' if a.player_feedback_pilot else 'test.feedback' if a.network_feedback_test else a.edition
        presets=re.sub(r'application/bundle_identifier="[^"]*"', 'application/bundle_identifier="com.wizardpc.von-neumann-bottleneck.'+bundle_suffix+'"', presets)
        presets=re.sub(r'application/short_version="[^"]*"', 'application/short_version="'+edition['display_version'].split('-')[0]+'"', presets)

    # Native numeric versions identify the frozen Git content without reusing a date label.
    revision=int(subprocess.check_output(['git','rev-list','--count',commit],cwd=root,text=True,encoding='utf-8'))
    numeric=((edition['display_version'].split('-')[0]+'.'+str(revision%65536)) if edition else '0.5.'+str(revision//65536)+'.'+str(revision%65536))
    for key in ['file_version','product_version']:
        presets=re.sub(r'application/'+key+r'="[^"]*"','application/'+key+'="'+numeric+'"',presets)
    mac_version=str(1+revision//10000)+'.'+str((revision//100)%100)+'.'+str(revision%100)
    presets=re.sub(r'application/version="[^"]*"','application/version="'+mac_version+'"',presets)
    if brand.get('native_icon_windows'):
        presets=presets.replace('[preset.0.options]','[preset.0.options]\napplication/icon="'+brand['native_icon_windows']+'"')
    if brand.get('native_icon_macos'):
        presets=presets.replace('[preset.1.options]','[preset.1.options]\napplication/icon="'+brand['native_icon_macos']+'"')
    if template:
        mac_path=godot_path_literal(template)
        presets=presets.replace('[preset.1.options]','[preset.1.options]\ncustom_template/debug='+mac_path+'\ncustom_template/release='+mac_path)
    if a.windows_template:
        presets=presets.replace('custom_template/release=""','custom_template/release='+godot_path_literal(a.windows_template),1)
    (project/'export_presets.cfg').write_text(presets,encoding='utf-8')
    original=re.sub(r'config/version="[^"]*"','config/version="'+(edition['display_version'] if edition else build_id)+'"',original)
    if edition:
        original=original.replace('[game]', '[game]\nedition='+json.dumps(a.edition), 1)
        original=original.replace('[application]', '[application]\nconfig/build_id='+json.dumps(build_id)+'\nconfig/edition='+json.dumps(edition['edition_name']), 1)
        original=re.sub(r'config/name="[^"]*"', 'config/name="Von Neumann Bottleneck — '+edition['edition_name']+'"', original)

    original=original.replace('[application]','[application]\nconfig/build_commit="'+commit+'"\nfeedback_endpoint='+json.dumps(a.feedback_endpoint)+'\ntest_batch='+json.dumps(a.test_batch or 'unspecified')+'\nfeedback_source_batch='+json.dumps(a.test_batch or 'free-alpha'))
    if a.public_playtest or a.offline_tester or 'feedback_default_source' in edition_feedback:original=original.replace('[application]','[application]\nfeedback_default_source="external_player"',1)
    if a.public_playtest or edition_feedback:original=original.replace('[application]','[application]\nfeedback_privacy_url='+json.dumps(a.privacy_url),1)
    if a.player_release:
        for key in ('public_game_feedback', 'public_test_feedback', 'community_feedback_enabled'):
            if key not in edition_feedback:
                continue
            original=original.replace('[application]', '[application]\n'+key+'='+json.dumps(edition_feedback[key]), 1)
    # Bind binary-exported scripts to the same workspace model fingerprints as source.
    workspace_versions={}
    for state in ['src/system_lab/system_chapter_state.gd','src/locality_chapter/locality_chapter_state.gd']:
        source=(project/state).read_text(encoding='utf-8')
        paths=json.loads(re.search(r'Workspace.fingerprint\((\[.*?\])\)',source).group(1))
        signature='workspace-v1'+''.join(hashlib.sha256((project/path.removeprefix('res://')).read_bytes()).hexdigest() for path in paths)
        workspace_versions[paths[0]]=hashlib.sha256(signature.encode()).hexdigest()
    original=original.replace('[application]','[application]\nworkspace_versions='+json.dumps(workspace_versions))
    if a.second_act_profile:
        if '[candidate]' in original or 'config/custom_user_dir_name=' in original or 'config/use_custom_user_dir=' in original:raise ValueError('Review existing candidate/user-directory configuration')
        original=original.replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name='+json.dumps('VonNeumannBottleneckCandidates/representation/'+a.second_act_profile),1)
        original+='\n[candidate]\nprimary_domain="representation"\nprofile='+json.dumps(a.second_act_profile)+'\njourney_enabled=true\n'
        if a.creation_journey:original+='creation_enabled=true\n'
    if a.offline_tester:original+='\n[playtest]\noffline_tester=true\n'
    if a.edition == 'test' and (dual_test or not edition_feedback):original+='\n[playtest]\noffline_feedback=true\n'
    (project/'project.godot').write_text(original,encoding='utf-8')
    identity='Build: '+build_id+'\nSource commit: '+commit+'\nGodot: '+engine+'\n'
    if edition:
        identity+='Edition: '+edition['edition_name']+'\nVersion: '+edition['release_version']+'\nBatch: '+edition['test_batch']+'\nContent: '+edition['content_version']+' (60 tasks)\nSave profile: '+edition['save_profile']+'\n'
    identity+='\n'
    for document in ['README.md','README.en.md','CHANGELOG.md','distribution/PLAYTEST-README.txt','distribution/CHANGELOG.txt','distribution/KNOWN-ISSUES.txt']:
        path=project/document
        path.write_text(identity+path.read_text(encoding='utf-8').replace('@BUILD_ID@',build_id).replace('@SOURCE_COMMIT@',commit),encoding='utf-8')
    if a.public_playtest:
        path=project/'distribution/PLAYTEST-README.txt'
        content=path.read_text(encoding='utf-8')
        replacements={
            '解压 Windows ZIP 后运行 Von-Neumann-Bottleneck.exe；Mac 运行 .app。':'解压 Windows ZIP 后运行 Von-Neumann-Bottleneck.exe。本次公开预发布仅提供 Windows。',
            'Extract and run the Windows EXE or macOS app.':'Extract and run the Windows EXE. This prerelease is Windows-only.',
        }
        for old,new in replacements.items():
            if old not in content:raise ValueError('Review changed public README wording: '+old)
            content=content.replace(old,new,1)
        path.write_text(content,encoding='utf-8')
        path=project/'distribution/KNOWN-ISSUES.txt'
        content=path.read_text(encoding='utf-8')
        replacements={
            '- Mac 包为 ad-hoc 签名、未公证；仍需另一台 Mac 核对安装、首启与保存。Windows 包未进行正式代码签名。':'- 本次不提供 Mac 包；Mac 候选的异机首启与存档尚未验收。Windows 包未进行正式代码签名。',
            '- 离线包的云端反馈入口为空。可保存/导出意见；已配置私有验收入口的包会明确单独标记，不能当作公网可用包。':'- 本公开试玩包配置了下方 HTTPS 反馈入口；发送意见须单独确认，自动统计默认关闭。',
            '- 未配置在线反馈接收端；本机保存与导出可用，离线游玩不依赖服务器。':'- 公开反馈入口与隐私说明见下方。构建本身不证明公网验收；离线游玩不依赖服务器。',
            'macOS is ad-hoc signed and unnotarized; independent Mac first-launch/save checks remain open.':'No macOS package is included in this prerelease; native Mac acceptance remains open.',
            'Offline packages have no feedback receiver. Explicit private acceptance builds are separately labelled.':'This public playtest configures the HTTPS receiver below. Automatic statistics remain off; sending an opinion requires separate consent. External acceptance is recorded separately.',
        }
        for old,new in replacements.items():
            if old not in content:raise ValueError('Review changed public known-issues wording: '+old)
            content=content.replace(old,new,1)
        content+='\n公开试玩版本 / Public prerelease: '+a.release_version+'\n反馈入口 / Feedback receiver: '+a.feedback_endpoint+'\n隐私说明 / Privacy notice: '+a.privacy_url+'\n'
        path.write_text(content,encoding='utf-8')
    isolated_base='\n'.join(line for line in original.splitlines() if not line.startswith(('config/use_custom_user_dir=','config/custom_user_dir_name=')))+'\n'
    isolated=isolated_base.replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="VonNeumannBottleneckChecks/build-'+stamp+'"')
    runtime_env=os.environ.copy()
    if os.name=='nt':
        for key,name in [('APPDATA','Roaming'),('LOCALAPPDATA','Local'),('TEMP','Temp'),('TMP','Temp')]:
            directory=work/'runtime'/name;directory.mkdir(parents=True,exist_ok=True)
            runtime_env[key]=str(directory)
    def run(name,args):
        result=subprocess.run([a.godot,'--headless','--path',str(project),*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=600,env=runtime_env)
        text=result.stdout+result.stderr;(work/(name+'.log')).write_text(text,encoding='utf-8')
        if result.returncode or 'SCRIPT ERROR' in text or 'ERROR:' in text:raise RuntimeError(name+' failed: '+str(work/(name+'.log')))
        print(name+': PASS',flush=True)
    (project/'project.godot').write_text('\n'.join(line for line in isolated.splitlines() if not line.startswith('theme/custom_font='))+'\n',encoding='utf-8')
    run('import',['--editor','--import','--quit'])
    (project/'project.godot').write_text(isolated,encoding='utf-8')
    # Read the exact engine's bundled licensing data, not a guessed dependency list.
    probe=project/'candidate_license_probe.gd'
    probe.write_text('extends SceneTree\nfunc _init() -> void:\n\tvar f=FileAccess.open("res://candidate-licenses.txt",FileAccess.WRITE)\n\tf.store_string(Engine.get_license_text()+"\\n\\n"+JSON.stringify(Engine.get_copyright_info(),"\\t")+"\\n\\n"+JSON.stringify(Engine.get_license_info(),"\\t"))\n\tf.close()\n\tquit()\n',encoding='utf-8')
    run('licenses',['--script','res://candidate_license_probe.gd']);probe.unlink()
    (project/'project.godot').write_text(original,encoding='utf-8')
    # Exporters themselves do not start the game. Native QA uses a separate override.
    manifest={'build_id':build_id,'source_commit':commit,'engine':engine,'created_utc':stamp,'public_release':a.public_playtest,'upload_default':False,'workspace_versions':workspace_versions,'feedback_endpoint':a.feedback_endpoint,'test_batch':a.test_batch or 'unspecified','external_ready':False,'local_acceptance_only':a.local_feedback_test,'content_version':'tasks-20261013-journey-v1' if a.second_act_profile or a.creation_journey else 'tasks-20260910-v1','branding':brand,'native_versions':{'windows':numeric,'macos':mac_version},'platforms':{}}
    if edition:manifest.update(edition)
    manifest.update(edition_feedback)
    if a.public_playtest:manifest.update(release_version=a.release_version,privacy_url=a.privacy_url,feedback_default_source='external_player')
    if a.offline_tester:manifest['offline_tester']=True
    rules=json.loads((project/'server/community_rules.json').read_text(encoding='utf-8'))
    manifest['content_tasks']=rules.get('content_manifests',{}).get(manifest['content_version'],{'tasks':rules['tasks']})['tasks']
    if not a.creation_journey:manifest['content_tasks']=[task for task in manifest['content_tasks'] if not task.startswith('creation/')]
    if a.windows_template:manifest['windows_template_sha256']=hashlib.sha256(a.windows_template.read_bytes()).hexdigest()
    if template:manifest['mac_template_sha256']=hashlib.sha256(template.read_bytes()).hexdigest()
    if a.second_act_profile:manifest['candidate_journey']={'primary_domain':'representation','profile':a.second_act_profile,'isolated':True,'production_migration':False}
    if a.creation_journey:manifest['candidate_journey']['creation_enabled']=True
    binary_name='Von-Neumann-Bottleneck'+('-'+a.edition.title() if edition else '')
    if a.player_feedback_pilot:
        binary_name += '-Pilot'
    platforms=[('macOS','macOS Free Candidate',binary_name+'.app'),('Windows','Windows Playtest',binary_name+'.exe')]
    for platform,preset,binary in platforms:
        if a.platform!='both' and platform!=a.platform:continue
        folder=output/platform;folder.mkdir()
        run('export-'+platform,['--export-release',preset,str(folder/binary)])
        for src,name in [('distribution/PLAYTEST-README.txt','README.txt'),('distribution/KNOWN-ISSUES.txt','KNOWN-ISSUES.txt'),('distribution/CHANGELOG.txt','CHANGELOG.txt'),('LICENSE','LICENSE.txt'),('distribution/THIRD-PARTY-NOTICES.txt','THIRD-PARTY-NOTICES.txt'),('distribution/NATURAL-EARTH-SOURCE.txt','NATURAL-EARTH-SOURCE.txt'),('assets/fonts/OFL-NotoSansSC.txt','FONT-LICENSE.txt'),('candidate-licenses.txt','ENGINE-LICENSES.txt')]:shutil.copy2(project/src,folder/name)
        if a.second_act_profile:
            with (folder/'README.txt').open('a',encoding='utf-8') as notes:
                notes.write('\nSecond-act isolated candidate journey\nProfile: '+a.second_act_profile+'\nRepresentation five tasks and Service three contracts have separate plans and endings. Save before leaving; the earned Representation review can continue to Service. Home recommends core construction/bottleneck work, the core ending, Representation, Service, and a saved four-page closing review. Timing and placement remain parallel; optional tasks are not required by this recommendation. The Journey map contains all core tasks, five Representation tasks, three Service contracts and three optional Prediction investigations. Select a task to enter its workbench and return through its existing save guard. Prediction remains temporary and is discarded on leaving; follow-up commissions remain optional. This build uses an isolated candidate profile and does not read or migrate production progress.\n')
                if a.creation_journey:
                    notes.write('\nCompression, content prediction and creation are also enabled: nine candidate units share the light-pattern workbench, learned rules and machine. The address-prediction investigations above remain separate and optional. Creation drafts, protected works and complete recipes use their own candidate session file; saved snapshots can be viewed, replayed or forked. '
                                +('This content does not migrate production saves.' if a.public_playtest else 'This is offline candidate content, not a production-save migration.')+'\n')
                if a.offline_tester:
                    notes.write('\nOffline teammate playtest: all sixty task entrances are available from a fresh profile. Entering a task does not complete it, unlock model actions, or grant saved evidence. Feedback stays on this computer until the tester deliberately exports a bundle. This build has no feedback receiver.\n')
        if a.test_batch:
            notes=folder/'README.txt'
            content=notes.read_text(encoding='utf-8')
            content=content.replace('本候选没有配置回传服务器','服务器地址与状态见下方本轮身份').replace('this build has no server URL','see this batch configuration below')
            content=content.replace('共 40 个任务','原核心 40 个任务').replace('Five regions, forty tasks.','Original core: five regions, forty tasks.')
            if a.second_act_profile:
                channel='VonNeumannBottleneckCandidates/representation/'+a.second_act_profile
                content=content.replace('~/Library/Application Support/Godot/app_userdata/Von Neumann Bottleneck/','~/Library/Application Support/'+channel+'/')
                content=content.replace('%APPDATA%/Godot/app_userdata/Von Neumann Bottleneck/','%APPDATA%/'+channel+'/')
                content+='\n本轮路线：先从首页推荐旅程/任务树开始，原核心结尾后继续表示与服务；C→P→G 在光纹工作台形成自己的作品和创造收尾。推荐与硬前置分开，可选地址预测不必通关。\n离开有保存提醒；首页继续定位最近任务。光纹工作台需明确保存草稿/作品；命名作品可回看、回放、派生，作品与完整配方受保护。\n反馈按钮在工作台、任务树与作品聚焦中可用，未通关也能发；退出不等待网络。仅保留本机、等待发送与服务器已收分开显示。\n'
                content+='服务数据另在同级 service/'+a.second_act_profile+'/；更新前备份这两个完整目录。测试渠道与正式存档隔离，不导入QA通关档。\n'
            content+='\n本轮测试批次 / Test batch: '+a.test_batch+'\n内容版本: '+manifest['content_version']+'\n实际任务: '+str(len(manifest['content_tasks']))+'（完整任务清单见 manifest.json）\n'
            content+='反馈入口: '+(a.feedback_endpoint or '未配置；仅本机保存/导出')+'\n自动统计默认关闭，单次意见独立授权；只有匹配服务器回执才标已收。\n'
            if a.public_playtest:content+='公开试玩版本 / Public prerelease: '+a.release_version+'\n隐私说明 / Privacy notice: '+a.privacy_url+'\n本构建未自行证明公网验收；请以独立验收记录为准。\n'
            content+='本地验收包，不能作为外部云端可用证据。\n' if a.local_feedback_test else '外部连接/平台实测以验收记录为准。\n'
            content+='测试存档渠道稳定，不随构建号清空；更新前完整备份候选profile及service同名目录。不要用QA通关档代替新档。\n'
            notes.write_text(content,encoding='utf-8')
        if a.offline_tester:
            offline_notes=offline_readme((project/'distribution/OFFLINE-PLAYTEST-README.txt').read_text(encoding='utf-8'),a.second_act_profile)
            (folder/'README.txt').write_text(identity+offline_notes,encoding='utf-8')
            package_offline_screenshots(project,folder)
            tools=folder/'feedback-tools';tools.mkdir()
            for name in ['offline-playtests.py','report-playtests.py']:
                shutil.copy2(project/'scripts'/name,tools/name)
            shutil.copy2(project/'distribution/OFFLINE-MAINTAINER.txt',tools/'README.txt')
        if edition:
            for name in ('README.txt', 'KNOWN-ISSUES.txt', 'CHANGELOG.txt'):
                notes = edition_notes(project, identity, edition, 'EDITION-' + name, binary_name)
                if a.network_feedback_test and name == 'README.txt':
                    notes = notes.replace(
                        '反馈保存在本机；可通过界面导出，只有你主动分享才会交给维护者。未配置在线接收端。\n'
                        'Feedback remains local and can be exported. Share it deliberately with the maintainer; no receiver is configured.',
                        '联网反馈验收版。F8 打开反馈表单，选定任务后可显式发送合成意见。自动统计默认关闭。\n'
                        'Network feedback acceptance build. Press F8, select a task, and explicitly send a synthetic opinion. Automatic statistics are off by default.\n'
                        f'Privacy / 隐私：{a.privacy_url}')
                if a.network_feedback_test and name == 'KNOWN-ISSUES.txt':
                    notes = notes.replace('没有联网依赖，也没有配置在线反馈接收端。', '联网反馈仅对获准测试来源开放。')
                    notes = notes.replace('No network is required and no feedback receiver is configured.', 'Online feedback is limited to approved test sources.')
                if a.player_feedback_pilot or (a.player_release and a.edition == 'game') or dual_test:
                    notes = online_player_notes(notes, name, edition_feedback, pilot=a.player_feedback_pilot)
                if a.player_release and a.edition == 'test' and not dual_test and name == 'README.txt':
                    notes = offline_capture_notes(notes)
                (folder / name).write_text(notes, encoding='utf-8')
        files={f.relative_to(folder).as_posix():hashlib.sha256(packaged_bytes(f)).hexdigest() for f in package_files(folder)}
        platform_manifest={'build_id':build_id,'source_commit':commit,'engine':engine,'platform':platform,'native_validation':'See verification record; export is not native acceptance','files_sha256':files}
        if edition:platform_manifest.update(edition)
        platform_manifest.update(edition_feedback)
        (folder/'BUILD-MANIFEST.json').write_text(json.dumps(platform_manifest,indent=2)+'\n',encoding='utf-8')
        zip_path=output/('Von-Neumann-Bottleneck-'+platform+'-'+build_id+'.zip')
        if platform=='macOS' and sys.platform=='darwin':subprocess.run(['/usr/bin/ditto','-c','-k','--sequesterRsrc','--keepParent',str(folder),str(zip_path)],check=True)
        else:
            with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
                for f in package_files(folder):write_zip_entry(z,f,f.relative_to(output))
        with zipfile.ZipFile(zip_path) as z:assert z.testzip() is None
        manifest['platforms'][platform]={'zip':zip_path.name,'bytes':zip_path.stat().st_size,'sha256':hashlib.sha256(zip_path.read_bytes()).hexdigest()}
    (output/'SHA256SUMS.txt').write_text(''.join(entry['sha256']+'  '+entry['zip']+'\n' for entry in manifest['platforms'].values()),encoding='utf-8')
    (output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    print('Candidates: '+str(output))
if __name__=='__main__':main()

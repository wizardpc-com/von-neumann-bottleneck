#!/usr/bin/env python3
"""Read-only consistency checks for a frozen local candidate directory."""
import argparse,hashlib,ipaddress,json,re,stat,zipfile
from pathlib import Path
from urllib.parse import urlsplit


def public_https_url(value, api_root=False):
    try:
        url=urlsplit(value)
        host=url.hostname or ''
        port=url.port
    except ValueError:
        return False
    try:ipaddress.ip_address(host)
    except ValueError:pass
    else:return False
    return (url.scheme=='https' and port in (None,443) and not url.username and not url.password
            and not url.query and not url.fragment
            and not host.endswith(('.local','.localhost','.test','.invalid','.example'))
            and re.fullmatch(r'(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}',host)
            and (not api_root or url.path==''))
p=argparse.ArgumentParser();p.add_argument('directory',type=Path);a=p.parse_args()
root=a.directory.resolve();manifest=json.loads((root/'manifest.json').read_text())
identity=manifest['build_id'];commit=manifest['source_commit']
batch=manifest.get('test_batch','unspecified')
expected=('playtest-'+batch+'-' if batch!='unspecified' else 'free-alpha-')+commit[:12]
assert identity==expected and root.name==identity
assert batch=='unspecified' or re.fullmatch(r'[A-Za-z0-9-]{1,40}',batch)
assert manifest['upload_default'] is False and manifest['external_ready'] is False
assert manifest['platforms'] and set(manifest['platforms']) <= {'macOS','Windows'}
if manifest['public_release']:
    assert set(manifest['platforms'])=={'Windows'} and not manifest['local_acceptance_only']
    assert manifest['release_version']=='v0.5.0-alpha.2' and re.fullmatch(r'[0-9a-f]{40}',commit)
    assert batch!='unspecified' and manifest['feedback_default_source']=='external_player'
    assert manifest['candidate_journey']=={'primary_domain':'representation','profile':'CloudPlaytest','isolated':True,'production_migration':False,'creation_enabled':True}
    assert manifest['content_version']=='tasks-20261013-journey-v1' and len(manifest['content_tasks'])==60
    assert len(set(manifest['content_tasks']))==60
    assert public_https_url(manifest['feedback_endpoint'],api_root=True) and public_https_url(manifest['privacy_url'])
else:
    assert 'release_version' not in manifest and 'privacy_url' not in manifest
if manifest.get('candidate_journey',{}).get('creation_enabled'):
    assert manifest['content_version'] in {'tasks-20261010-journey-v1','tasks-20261012-journey-v1','tasks-20261013-journey-v1'} and len(manifest['content_tasks'])==60
    assert manifest['candidate_journey']['isolated'] is True and manifest['candidate_journey']['production_migration'] is False
for platform,entry in manifest['platforms'].items():
    archive=root/entry['zip']
    assert archive.parent==root and identity in archive.name and archive.stat().st_size==entry['bytes']
    assert hashlib.sha256(archive.read_bytes()).hexdigest()==entry['sha256']
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
        names=package.namelist()
        assert len(names)==len(set(names))
        metadata=json.loads(package.read(platform+'/BUILD-MANIFEST.json'))
        assert metadata['build_id']==identity and metadata['source_commit']==commit
        assert metadata['engine']==manifest['engine'] and metadata['platform']==platform
        required={'README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt','LICENSE.txt','FONT-LICENSE.txt','ENGINE-LICENSES.txt'}
        assert required <= set(metadata['files_sha256'])
        expected_files={platform+'/'+filename for filename in metadata['files_sha256']}
        expected_files.add(platform+'/BUILD-MANIFEST.json')
        actual_files={name for name in names if name.startswith(platform+'/') and not name.endswith('/')}
        assert actual_files==expected_files
        if platform=='macOS':
            executables=[package.getinfo(name) for name in actual_files if '.app/Contents/MacOS/' in name]
            assert executables and all(info.external_attr >> 16 & stat.S_IXUSR for info in executables)
        for filename,digest in metadata['files_sha256'].items():
            assert filename and not filename.startswith('/') and '..' not in Path(filename).parts
            assert hashlib.sha256(package.read(platform+'/'+filename)).hexdigest()==digest,filename
        for filename in ['README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt']:
            body=package.read(platform+'/'+filename).decode().replace('\r\n','\n')
            assert body.startswith('Build: '+identity+'\nSource commit: '+commit+'\n')
            assert '@BUILD_ID@' not in body and '@SOURCE_COMMIT@' not in body
            if manifest['public_release'] and filename!='CHANGELOG.txt':
                assert manifest['release_version'] in body and manifest['feedback_endpoint'] in body and manifest['privacy_url'] in body
print('PASS: source/build identity, archive names, all file hashes and packaged notes agree: '+identity)

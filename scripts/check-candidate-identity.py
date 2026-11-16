#!/usr/bin/env python3
"""Read-only consistency checks for a frozen local candidate directory."""
import argparse,hashlib,ipaddress,json,re,stat,struct,zipfile
from pathlib import Path
from urllib.parse import urlsplit


def archive_index(package, platform):
    """ditto writes UTF-8 names without bit 11; keep ZipInfo for byte reads."""
    entries={}
    for info in package.infolist():
        assert info.orig_filename==info.filename, 'Truncated ZIP path'
        name=info.filename
        if platform=='macOS' and not info.flag_bits & 0x800:
            name=name.encode('cp437').decode('utf-8',errors='strict')
        path=name[:-1] if info.is_dir() else name
        assert path and '\\' not in path and not any(ord(c)<32 for c in path),name
        assert all(part not in {'','.', '..'} and ':' not in part for part in path.split('/')),name
        assert path not in entries,'Duplicate normalized ZIP path: '+path
        entries[path]=info
    return entries


def verify_inventory(package, entries, expected_files, platform):
    directories={name.rsplit('/',1)[0] for name in expected_files}
    for directory in list(directories):
        parts=directory.split('/')
        directories.update('/'.join(parts[:i]) for i in range(1,len(parts)))
    # Godot's macOS template includes this empty standard bundle directory.
    if platform=='macOS':
        for name in expected_files:
            if name.endswith('.app/Contents/Info.plist'):
                frameworks=name.rsplit('/',1)[0]+'/Frameworks'
                if frameworks in entries and entries[frameworks].is_dir():
                    directories.add(frameworks)
    product_files=set()
    metadata_files=set()
    for name,info in entries.items():
        if name.startswith('__MACOSX/') and not info.is_dir():
            assert platform=='macOS',name
            relative=name[len('__MACOSX/'):]
            parent,leaf=relative.rsplit('/',1)
            assert leaf.startswith('._') and len(leaf)>2,name
            target=parent+'/'+leaf[2:]
            assert target in expected_files or target in directories,name
            data=package.read(info)
            assert len(data)>=26,name
            magic,version=struct.unpack_from('>II',data)
            count=struct.unpack_from('>H',data,24)[0]
            assert (magic,version)==(0x00051607,0x00020000) and 1<=count<=2,name
            table_end=26+12*count
            assert table_end<=len(data),name
            ids=set();ranges=[]
            for index in range(count):
                kind,offset,length=struct.unpack_from('>III',data,26+12*index)
                assert kind in {2,9} and kind not in ids,name
                assert table_end<=offset<=len(data) and offset+length<=len(data),name
                ids.add(kind)
                if length:ranges.append((offset,offset+length))
            ranges.sort()
            assert all(a[1]<=b[0] for a,b in zip(ranges,ranges[1:])),name
            metadata_files.add(name)
        elif not info.is_dir():
            product_files.add(name)
    assert product_files==expected_files, (product_files-expected_files,expected_files-product_files)
    metadata_directories=set()
    for name in metadata_files:
        parts=name.split('/')
        metadata_directories.update('/'.join(parts[:i]) for i in range(1,len(parts)))
    for name,info in entries.items():
        if info.is_dir():assert name in directories or name in metadata_directories,name


def public_https_url(value, api_root=False):
    if any(ord(char)<32 for char in value) or (not api_root and len(value)>2048):
        return False
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
            and re.fullmatch(r'https://[a-z0-9.-]+(?::443)?'+(r'' if api_root else r'(?:/[A-Za-z0-9._~/-]*)?'),value) is not None)
p=argparse.ArgumentParser();p.add_argument('directory',type=Path);a=p.parse_args()
root=a.directory.resolve();manifest=json.loads((root/'manifest.json').read_text())
identity=manifest['build_id'];commit=manifest['source_commit']
batch=manifest.get('test_batch','unspecified')
edition=manifest.get('edition')
expected=('vnb-'+edition+'-'+manifest['release_version']+'-'+batch+'-'+commit[:12] if edition else
          ('playtest-'+batch+'-' if batch!='unspecified' else 'free-alpha-')+commit[:12])
assert identity==expected and root.name==identity
assert batch=='unspecified' or re.fullmatch(r'[A-Za-z0-9-]{1,40}',batch)
assert manifest['upload_default'] is False and manifest['external_ready'] is False
assert manifest['platforms'] and set(manifest['platforms']) <= {'macOS','Windows'}
if edition:
    assert edition in {'game','test'} and re.fullmatch(r'[0-9a-f]{40}',commit)
    version=manifest['release_version']
    assert re.fullmatch(r'v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?',version)
    profile='EditionGame' if edition=='game' else 'EditionTest'
    assert manifest['edition_name']==edition.title()+' Edition' and manifest['display_version']==version[1:]
    assert manifest['save_profile']==profile and manifest['save_directories']==[
        'VonNeumannBottleneckCandidates/'+domain+'/'+profile for domain in ('representation','service')]
    assert manifest['mode_locked'] is True and manifest['save_migration'] is False
    assert manifest['access_policy']==('earned' if edition=='game' else 'all-task-entrances')
    assert manifest['content_count']==60 and len(set(manifest['content_tasks']))==60
    assert manifest['content_version']=='tasks-20261013-journey-v1'
    assert manifest['feedback_endpoint']=='' and not manifest['public_release'] and not manifest['local_acceptance_only']
    assert not manifest.get('offline_tester',False) and batch!='unspecified'
    assert manifest['candidate_journey']=={'primary_domain':'representation','profile':profile,'isolated':True,'production_migration':False,'creation_enabled':True}
    sums=(root/'SHA256SUMS.txt').read_text()
    assert sums==''.join(entry['sha256']+'  '+entry['zip']+'\n' for entry in manifest['platforms'].values())
if manifest.get('offline_tester',False):
    assert manifest['public_release'] is False and not manifest['local_acceptance_only']
    assert 'feedback_default_source' not in manifest
    assert set(manifest['platforms'])=={'Windows'} and manifest['feedback_endpoint']==''
    assert batch!='unspecified' and re.fullmatch(r'[0-9a-f]{40}',commit)
    profile=manifest['candidate_journey'].get('profile','')
    assert isinstance(profile,str) and len(profile)<=40 and re.fullmatch(r'OfflineTeammate(?:-[A-Za-z0-9-]+)?',profile)
    assert manifest['candidate_journey']=={'primary_domain':'representation','profile':profile,'isolated':True,'production_migration':False,'creation_enabled':True}
    assert manifest['content_version']=='tasks-20261013-journey-v1' and len(manifest['content_tasks'])==60
    assert len(set(manifest['content_tasks']))==60
if manifest['public_release']:
    assert not manifest.get('offline_tester',False)
    assert set(manifest['platforms'])=={'Windows'} and not manifest['local_acceptance_only']
    assert manifest['release_version']=='v0.5.0-alpha.2' and re.fullmatch(r'[0-9a-f]{40}',commit)
    assert batch!='unspecified' and manifest['feedback_default_source']=='external_player'
    assert manifest['candidate_journey']=={'primary_domain':'representation','profile':'CloudPlaytest','isolated':True,'production_migration':False,'creation_enabled':True}
    assert manifest['content_version']=='tasks-20261013-journey-v1' and len(manifest['content_tasks'])==60
    assert len(set(manifest['content_tasks']))==60
    assert public_https_url(manifest['feedback_endpoint'],api_root=True) and public_https_url(manifest['privacy_url'])
else:
    assert (edition or 'release_version' not in manifest) and 'privacy_url' not in manifest
if manifest.get('candidate_journey',{}).get('creation_enabled'):
    assert manifest['content_version'] in {'tasks-20261010-journey-v1','tasks-20261012-journey-v1','tasks-20261013-journey-v1'} and len(manifest['content_tasks'])==60
    assert manifest['candidate_journey']['isolated'] is True and manifest['candidate_journey']['production_migration'] is False
for platform,entry in manifest['platforms'].items():
    archive=root/entry['zip']
    assert archive.parent==root and identity in archive.name and archive.stat().st_size==entry['bytes']
    assert hashlib.sha256(archive.read_bytes()).hexdigest()==entry['sha256']
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
        entries=archive_index(package,platform)
        metadata=json.loads(package.read(entries[platform+'/BUILD-MANIFEST.json']))
        assert metadata['build_id']==identity and metadata['source_commit']==commit
        assert metadata['engine']==manifest['engine'] and metadata['platform']==platform
        if edition:
            for key in ['edition','edition_name','release_version','display_version','source_commit','test_batch',
                        'save_profile','save_directories','content_version','content_count','access_policy','mode_locked','save_migration']:
                assert metadata[key]==manifest[key],key
        required={'README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt','LICENSE.txt','FONT-LICENSE.txt','ENGINE-LICENSES.txt'}
        assert required <= set(metadata['files_sha256'])
        expected_files={platform+'/'+filename for filename in metadata['files_sha256']}
        expected_files.add(platform+'/BUILD-MANIFEST.json')
        verify_inventory(package,entries,expected_files,platform)
        if platform=='macOS':
            executables=[entries[name] for name in expected_files if '.app/Contents/MacOS/' in name]
            assert executables and all(info.external_attr >> 16 & stat.S_IXUSR for info in executables)
        for filename,digest in metadata['files_sha256'].items():
            assert filename and not filename.startswith('/') and '..' not in Path(filename).parts
            assert hashlib.sha256(package.read(entries[platform+'/'+filename])).hexdigest()==digest,filename
        for filename in ['README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt']:
            body=package.read(entries[platform+'/'+filename]).decode().replace('\r\n','\n')
            assert body.startswith('Build: '+identity+'\nSource commit: '+commit+'\n')
            assert '@BUILD_ID@' not in body and '@SOURCE_COMMIT@' not in body
            if edition:
                for text in ['Edition: '+manifest['edition_name'],'Version: '+manifest['release_version'],
                             'Batch: '+batch,'Save profile: '+profile,'Content: '+manifest['content_version']+' (60 tasks)']:
                    assert text in body,(filename,text)
                assert not re.search(r'@[A-Z_]+@',body)
                if filename=='README.txt':
                    for directory in manifest['save_directories']:
                        assert '~/Library/Application Support/'+directory+'/' in body
                        assert '%APPDATA%/'+directory+'/' in body
            if manifest['public_release'] and filename!='CHANGELOG.txt':
                assert manifest['release_version'] in body and manifest['feedback_endpoint'] in body and manifest['privacy_url'] in body
            if manifest.get('offline_tester',False) and filename=='README.txt':
                assert '%APPDATA%/VonNeumannBottleneckCandidates/representation/'+profile+'/' in body
                assert 'service/'+profile+'/' in body
                assert profile=='OfflineTeammate' or '/OfflineTeammate/' not in body
print('PASS: source/build identity, archive names, all file hashes and packaged notes agree: '+identity)

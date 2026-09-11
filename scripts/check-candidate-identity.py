#!/usr/bin/env python3
"""Read-only consistency checks for a frozen local candidate directory."""
import argparse,hashlib,json,zipfile
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('directory',type=Path);a=p.parse_args()
root=a.directory.resolve();manifest=json.loads((root/'manifest.json').read_text())
identity=manifest['build_id'];commit=manifest['source_commit']
assert identity=='free-alpha-'+commit[:12] and root.name==identity
assert manifest['public_release'] is False and manifest['upload_default'] is False
for platform,entry in manifest['platforms'].items():
    archive=root/entry['zip']
    assert identity in archive.name and hashlib.sha256(archive.read_bytes()).hexdigest()==entry['sha256']
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
        metadata=json.loads(package.read(platform+'/BUILD-MANIFEST.json'))
        assert metadata['build_id']==identity and metadata['source_commit']==commit
        for filename,digest in metadata['files_sha256'].items():
            assert hashlib.sha256(package.read(platform+'/'+filename)).hexdigest()==digest,filename
        for filename in ['README.txt','CHANGELOG.txt','KNOWN-ISSUES.txt']:
            body=package.read(platform+'/'+filename).decode()
            assert body.startswith('Build: '+identity+'\nSource commit: '+commit+'\n')
            assert '@BUILD_ID@' not in body and '@SOURCE_COMMIT@' not in body
print('PASS: source/build identity, archive names, all file hashes and packaged notes agree: '+identity)

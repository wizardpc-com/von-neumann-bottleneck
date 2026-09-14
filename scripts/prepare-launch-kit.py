#!/usr/bin/env python3
"""Validate and bundle reviewed contest material locally; never publish anything."""
import argparse
import hashlib
import json
from pathlib import Path
import struct
import zipfile

ROOT = Path(__file__).resolve().parents[1]
KIT = ROOT / 'docs/distribution/astra-challenge'

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    fields = json.loads((KIT / 'submission.json').read_text())
    if not 0 < len(fields['tagline']) <= 60 or not 0 < len(fields['description']) <= 500:
        raise ValueError('Product Hunt field length exceeded')
    manifest = json.loads((KIT / 'gallery/manifest.json').read_text())
    if len(manifest['images']) < 2:
        raise ValueError('At least two gallery images required')
    for row in manifest['images']:
        path = (KIT / 'gallery' / row['file']).resolve()
        if path.parent != (KIT / 'gallery').resolve():
            raise ValueError('Unexpected image path')
        data = path.read_bytes()
        if data[:8] != b'\x89PNG\r\n\x1a\n' or hashlib.sha256(data).hexdigest() != row['sha256']:
            raise ValueError('Image identity changed: ' + row['file'])
        if list(struct.unpack('>II', data[16:24])) != row['dimensions']:
            raise ValueError('Image dimensions changed')
    files = sorted(p for p in KIT.rglob('*') if p.suffix in {'.md', '.json', '.png'})
    args.output.parent.mkdir(parents=True, exist_ok=True)
    # Exclusive creation prevents silently replacing a previously reviewed bundle.
    with zipfile.ZipFile(args.output, 'x', zipfile.ZIP_DEFLATED) as output:
        for path in files:
            output.write(path, 'VNB-launch-kit/' + path.relative_to(KIT).as_posix())
    print(json.dumps({'status': 'prepared_not_published', 'files': len(files),
        'tagline_characters': len(fields['tagline']), 'description_characters': len(fields['description']),
        'download_url_configured': bool(fields['public_download_url']),
        'zip': str(args.output.resolve()),
        'sha256': hashlib.sha256(args.output.read_bytes()).hexdigest()}, indent=2))

if __name__ == '__main__':
    main()

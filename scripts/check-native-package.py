#!/usr/bin/env python3
"""Read-only native architecture, icon and signature checks for frozen packages.

Windows PE parsing uses only Python's standard library. macOS checks use Apple's
lipo, codesign and sips. This verifies package structure, not native gameplay.
"""
import argparse
import hashlib
import json
from pathlib import Path
import plistlib
import struct
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def unpack(data, fmt, offset):
    size = struct.calcsize(fmt)
    if offset < 0 or offset + size > len(data):
        raise ValueError('Truncated structure at offset %s' % offset)
    return struct.unpack_from(fmt, data, offset)


def png_size(data):
    if data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
        raise ValueError('Expected PNG icon payload')
    return unpack(data, '>II', 16)


def ico_entries(path):
    data = path.read_bytes()
    reserved, kind, count = unpack(data, '<HHH', 0)
    if reserved != 0 or kind != 1 or count < 1 or count > 256:
        raise ValueError('Invalid reference ICO directory')
    result = {}
    for index in range(count):
        width, height, _, _, planes, depth, length, offset = unpack(data, '<BBBBHHII', 6 + 16 * index)
        size = (width or 256, height or 256)
        if offset < 6 + 16 * count or offset + length > len(data) or planes != 1 or depth != 32:
            raise ValueError('Invalid reference ICO entry')
        payload = data[offset:offset + length]
        if png_size(payload) != size or size in result:
            raise ValueError('Reference ICO dimensions differ or repeat')
        result[size] = payload
    return result


class PE:
    def __init__(self, path):
        self.data = path.read_bytes()
        if self.data[:2] != b'MZ':
            raise ValueError('Windows file lacks DOS signature')
        pe, = unpack(self.data, '<I', 0x3c)
        if self.data[pe:pe + 4] != b'PE\0\0':
            raise ValueError('Windows file lacks PE signature')
        machine, sections, _, _, _, optional_size, _ = unpack(self.data, '<HHIIIHH', pe + 4)
        if machine != 0x8664:
            raise ValueError('Expected Windows x86_64 PE machine, got 0x%x' % machine)
        optional = pe + 24
        magic, = unpack(self.data, '<H', optional)
        directories, = unpack(self.data, '<I', optional + 108)
        if magic != 0x20b or optional_size < 136 or directories < 3:
            raise ValueError('Expected PE32+ optional header with resource directory')
        self.sections = []
        for index in range(sections):
            offset = optional + optional_size + 40 * index
            name, virtual_size, virtual_address, raw_size, raw_offset = unpack(self.data, '<8sIIII', offset)
            self.sections.append((virtual_address, virtual_size, raw_offset, raw_size))
        resource_rva, self.resource_size = unpack(self.data, '<II', optional + 112 + 16)
        if not resource_rva or self.resource_size < 16:
            raise ValueError('PE has no native resources')
        self.resource_base = self.rva_offset(resource_rva, self.resource_size)
        self.resources = []
        self._directory(0, [], set())

    def rva_offset(self, rva, size):
        for virtual, virtual_size, raw, raw_size in self.sections:
            relative = rva - virtual
            if 0 <= relative and relative + size <= raw_size:
                offset = raw + relative
                if offset + size <= len(self.data):
                    return offset
        raise ValueError('PE resource RVA 0x%x is outside initialized file sections' % rva)

    def resource_offset(self, relative, size):
        if relative < 0 or relative + size > self.resource_size:
            raise ValueError('Resource directory points outside resource section')
        return self.resource_base + relative

    def _directory(self, relative, keys, ancestors):
        if relative in ancestors or len(keys) > 3:
            raise ValueError('Cyclic or excessive PE resource hierarchy')
        offset = self.resource_offset(relative, 16)
        named, numeric = unpack(self.data, '<HH', offset + 12)
        count = named + numeric
        self.resource_offset(relative + 16, count * 8)
        for index in range(count):
            name, target = unpack(self.data, '<II', offset + 16 + index * 8)
            if name & 0x80000000:
                string_offset = name & 0x7fffffff
                string_base = self.resource_offset(string_offset, 2)
                length, = unpack(self.data, '<H', string_base)
                self.resource_offset(string_offset + 2, length * 2)
                key = self.data[string_base + 2:string_base + 2 + length * 2].decode('utf-16le')
            else:
                key = name
            if target & 0x80000000:
                self._directory(target & 0x7fffffff, keys + [key], ancestors | {relative})
            else:
                entry = self.resource_offset(target, 16)
                rva, length, codepage, _ = unpack(self.data, '<IIII', entry)
                payload_offset = self.rva_offset(rva, length)
                path = keys + [key]
                if len(path) != 3:
                    raise ValueError('Expected type/name/language resource path')
                self.resources.append({'type': path[0], 'id': path[1], 'language': path[2],
                                       'payload': self.data[payload_offset:payload_offset + length]})


def version_info(data):
    length, value_length, kind = unpack(data, '<HHH', 0)
    if length > len(data) or length < 6 or value_length < 52 or kind != 0:
        raise ValueError('Invalid VS_VERSIONINFO root')
    end = 6
    while end + 2 <= length and data[end:end + 2] != b'\0\0':
        end += 2
    if end + 2 > length or data[6:end].decode('utf-16le') != 'VS_VERSION_INFO':
        raise ValueError('Invalid version resource key')
    value_offset = (end + 2 + 3) & ~3
    if value_offset + value_length > length:
        raise ValueError('Version value exceeds resource root')
    fixed = unpack(data, '<13I', value_offset)
    if fixed[0] != 0xfeef04bd:
        raise ValueError('Invalid VS_FIXEDFILEINFO signature')
    def version(ms, ls):
        return '.'.join(str(x) for x in (ms >> 16, ms & 65535, ls >> 16, ls & 65535))
    return {'file_version': version(fixed[2], fixed[3]),
            'product_version': version(fixed[4], fixed[5]), 'sha256': sha256(data)}


def check_windows(path, ico, expected_version=None):
    pe = PE(path)
    reference = ico_entries(ico)
    groups = [r for r in pe.resources if r['type'] == 14]
    if not groups:
        raise ValueError('Windows EXE lacks RT_GROUP_ICON')
    # Windows selects the first resource group; do not certify some unrelated
    # secondary group while the actual default application icon is different.
    groups.sort(key=lambda r: (isinstance(r['id'], int), str(r['id']) if isinstance(r['id'], str) else r['id'], str(r['language'])))
    group = groups[0]
    data = group['payload']
    reserved, kind, count = unpack(data, '<HHH', 0)
    if reserved != 0 or kind != 1 or count < 1 or len(data) != 6 + count * 14:
        raise ValueError('Invalid primary Windows group icon')
    observed = {}
    for index in range(count):
        width, height, _, _, planes, depth, length, resource_id = unpack(data, '<BBBBHHIH', 6 + 14 * index)
        size = (width or 256, height or 256)
        icons = [r for r in pe.resources if r['type'] == 3 and r['id'] == resource_id]
        same_language = [r for r in icons if r['language'] == group['language']]
        icons = same_language or [r for r in icons if r['language'] == 0]
        if len(icons) != 1:
            raise ValueError('Missing or ambiguous RT_ICON %s for primary group' % resource_id)
        payload = icons[0]['payload']
        if len(payload) != length or planes != 1 or depth != 32 or png_size(payload) != size:
            raise ValueError('Windows group icon metadata differs from PNG payload')
        if size in observed or size not in reference or payload != reference[size]:
            raise ValueError('Windows icon %sx%s differs from authored ICO PNG bytes' % size)
        observed[size] = sha256(payload)
    # Godot's Windows exporter retains these standard desktop sizes, omitting
    # optional source entries such as 24 px. Every retained payload above still
    # has to match the authored ICO byte-for-byte; no resampling is accepted.
    required_sizes = {(size, size) for size in (16, 32, 48, 64, 128, 256)}
    if not required_sizes <= set(observed):
        raise ValueError('Windows primary icon lacks a required standard size')
    versions = [version_info(r['payload']) for r in pe.resources if r['type'] == 16]
    if not versions:
        raise ValueError('Windows EXE lacks a valid version resource')
    if expected_version and any(v['file_version'] != expected_version or v['product_version'] != expected_version for v in versions):
        raise ValueError('Windows native file/product version differs from --version')
    return {'path': str(path.resolve()), 'architecture': 'x86_64', 'sha256': sha256(pe.data),
            'icon_reference': str(ico.resolve()), 'icon_group': group['id'], 'icon_language': group['language'],
            'icon_pngs': {('%sx%s' % size): digest for size, digest in sorted(observed.items())},
            'omitted_reference_sizes': ['%sx%s' % size for size in sorted(set(reference) - set(observed))],
            'versions': versions, 'passed': True}


def run(command):
    process = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if process.returncode:
        raise ValueError('Command failed: %s: %s' % (' '.join(map(str, command)), (process.stderr or process.stdout).strip()))
    return (process.stdout + process.stderr).strip()


def check_mac(app, icns, expected_bundle=None, expected_version=None):
    contents = app / 'Contents'
    with (contents / 'Info.plist').open('rb') as stream:
        info = plistlib.load(stream)
    executable_name = info.get('CFBundleExecutable', '')
    icon_name = info.get('CFBundleIconFile', '')
    if not executable_name or Path(executable_name).name != executable_name:
        raise ValueError('Invalid macOS executable name')
    if not icon_name or Path(icon_name).name != icon_name:
        raise ValueError('Invalid macOS icon name')
    executable = contents / 'MacOS' / executable_name
    if not executable.is_file() or not executable.stat().st_mode & 0o111:
        raise ValueError('macOS binary is absent or lacks executable mode')
    architectures = run(['/usr/bin/lipo', '-archs', str(executable)]).split()
    if set(architectures) != {'x86_64', 'arm64'}:
        raise ValueError('Expected macOS Universal x86_64+arm64, got ' + ' '.join(architectures))
    signature = run(['/usr/bin/codesign', '--verify', '--deep', '--strict', '--verbose=2', str(app)])
    details = run(['/usr/bin/codesign', '--display', '--verbose=2', str(app)])
    bundle_id = info.get('CFBundleIdentifier', '')
    version = info.get('CFBundleShortVersionString', '')
    if not bundle_id or (expected_bundle and bundle_id != expected_bundle):
        raise ValueError('macOS bundle identifier missing or different from --bundle-id')
    if not version or (expected_version and version != expected_version):
        raise ValueError('macOS version missing or different from --version')
    icon = contents / 'Resources' / (icon_name if icon_name.endswith('.icns') else icon_name + '.icns')
    actual = icon.read_bytes()
    expected = icns.read_bytes()
    if actual != expected or actual[:4] != b'icns' or unpack(actual, '>I', 4)[0] != len(actual):
        raise ValueError('macOS native icon differs from authored ICNS')
    decode = run(['/usr/bin/sips', '-g', 'pixelWidth', '-g', 'pixelHeight', str(icon)])
    if 'pixelWidth: 1024' not in decode or 'pixelHeight: 1024' not in decode:
        raise ValueError('macOS ICNS did not decode at 1024x1024')
    return {'path': str(app.resolve()), 'architectures': sorted(architectures),
            'executable_sha256': sha256(executable.read_bytes()), 'bundle_identifier': bundle_id,
            'version': version, 'build_version': info.get('CFBundleVersion', ''),
            'icon': str(icon.resolve()), 'icon_sha256': sha256(actual), 'icon_decoded_size': [1024, 1024],
            'codesign_verification': signature, 'codesign_details': details, 'passed': True}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--windows', type=Path)
    parser.add_argument('--ico', type=Path, default=ROOT / 'assets/branding/game-icon.ico')
    parser.add_argument('--mac-app', type=Path)
    parser.add_argument('--icns', type=Path, default=ROOT / 'assets/branding/game-icon.icns')
    parser.add_argument('--version', help='Optional expected native file/product or macOS short version')
    parser.add_argument('--bundle-id', help='Optional expected macOS CFBundleIdentifier')
    args = parser.parse_args()
    if not args.windows and not args.mac_app:
        parser.error('Provide --windows, --mac-app, or both')
    report = {'passed': True, 'scope': 'native package structure; not native gameplay'}
    for name, action in [('windows', lambda: check_windows(args.windows, args.ico, args.version)),
                         ('macos', lambda: check_mac(args.mac_app, args.icns, args.bundle_id, args.version))]:
        if (name == 'windows' and not args.windows) or (name == 'macos' and not args.mac_app):
            continue
        try:
            report[name] = action()
        except (OSError, ValueError, struct.error, plistlib.InvalidFileException) as error:
            report[name] = {'passed': False, 'error': str(error)}
            report['passed'] = False
    print(json.dumps(report, ensure_ascii=False, sort_keys=True))
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    sys.exit(main())

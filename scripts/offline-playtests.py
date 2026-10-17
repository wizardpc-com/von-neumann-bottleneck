#!/usr/bin/env python3
"""Validate private offline playtest exports and render a local review report."""
import argparse
from collections import Counter, defaultdict
from datetime import datetime
import hashlib
import html
import importlib.util
import json
import math
import os
from pathlib import Path
import re
import shutil
import stat
import sys
import tempfile
import zipfile


FORMAT = 'vnb-offline-playtest'
HEX32 = re.compile(r'[0-9a-f]{32}\Z')
HEX64 = re.compile(r'[0-9a-f]{64}\Z')
MAX_FILE = 64 * 1024 * 1024
MAX_TOTAL = 1024 * 1024 * 1024
MAX_ZIP = 1024 * 1024 * 1024
MAX_ENTRIES = 10000
MAX_JSON = 2 * 1024 * 1024
SCREENSHOT_STATUSES = {'captured', 'headless', 'unavailable', 'failed'}
CASE_STATUSES = {'draft', 'reported'}
WINDOWS_RESERVED = re.compile(r'(?i)(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?\Z')


class InvalidBundle(ValueError):
    pass


def utc_time(value, label):
    if not isinstance(value, str) or not value.endswith('Z'):
        raise InvalidBundle(label + ' must be a UTC timestamp')
    try:
        parsed = datetime.fromisoformat(value[:-1] + '+00:00')
    except ValueError as error:
        raise InvalidBundle(label + ' must be a UTC timestamp') from error
    if parsed.utcoffset().total_seconds() != 0:
        raise InvalidBundle(label + ' must be a UTC timestamp')
    return parsed


def json_document(data, label, limit=MAX_JSON):
    if len(data) > limit:
        raise InvalidBundle(label + ' exceeds JSON limit')
    def unique(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise InvalidBundle(label + ' has duplicate JSON keys')
            result[key] = value
        return result
    try:
        document = json.loads(data.decode('utf-8'), object_pairs_hook=unique,
                              parse_constant=lambda _: (_ for _ in ()).throw(InvalidBundle(label + ' has nonfinite number')))
        json.dumps(document, ensure_ascii=False).encode('utf-8')
        return document
    except (UnicodeError, json.JSONDecodeError, RecursionError) as error:
        raise InvalidBundle(label + ' is not valid UTF-8 JSON') from error


def safe_name(name):
    if not isinstance(name, str) or not name or '\\' in name or '\x00' in name or name.startswith('/'):
        raise InvalidBundle('unsafe ZIP path')
    if name.endswith('//'):
        raise InvalidBundle('unsafe ZIP path')
    parts = name.rstrip('/').split('/')
    if any(not part or part in ('.', '..') or ':' in part or part[-1] in (' ', '.')
           or WINDOWS_RESERVED.fullmatch(part) or any(ord(c) < 32 for c in part) for part in parts):
        raise InvalidBundle('unsafe ZIP path')
    return name


def zip_entries(archive):
    entries = {}
    folded = set()
    for info in archive.infolist():
        safe_name(info.filename)
        key = info.filename.rstrip('/').casefold()
        if key in folded:
            raise InvalidBundle('duplicate ZIP path: ' + info.filename)
        folded.add(key)
        mode = (info.external_attr >> 16) & 0o170000
        if mode not in (0, stat.S_IFDIR if info.is_dir() else stat.S_IFREG):
            raise InvalidBundle('non-regular ZIP entry: ' + info.filename)
        if info.flag_bits & 1:
            raise InvalidBundle('encrypted ZIP entry')
        if not info.is_dir():
            if info.file_size > MAX_FILE:
                raise InvalidBundle('ZIP member exceeds file limit: ' + info.filename)
            entries[info.filename] = info
    if len(archive.infolist()) > MAX_ENTRIES or sum(item.file_size for item in entries.values()) > MAX_TOTAL:
        raise InvalidBundle('ZIP exceeds entry or expanded-size limit')
    return entries


def validate_case(path, root):
    case = json_document((root / path / 'case.json').read_bytes(), path + '/case.json', MAX_FILE)
    context = json_document((root / path / 'context.json').read_bytes(), path + '/context.json', MAX_FILE)
    case_id = path.split('/')[1]
    if (not isinstance(case, dict) or case.get('id') != case_id
            or not isinstance(case.get('category'), str) or not isinstance(case.get('note'), str)
            or not isinstance(case.get('task'), dict) or not isinstance(context, dict)
            or case.get('screenshot_status') not in SCREENSHOT_STATUSES
            or not isinstance(case.get('screenshot_error'), str)
            or case.get('status') not in CASE_STATUSES
            or type(case.get('revision')) is not int or case['revision'] < 0):
        raise InvalidBundle('invalid case metadata: ' + path)
    utc_time(case.get('captured_at_utc'), path + '.captured_at_utc')
    utc_time(case.get('updated_at_utc'), path + '.updated_at_utc')
    if 'build' in case:
        build = case['build']
        if (not isinstance(build, dict)
                or any(not isinstance(build.get(key), str) for key in ('version', 'source_commit', 'engine', 'platform'))
                or type(build.get('offline_tester')) is not bool):
            raise InvalidBundle('invalid captured build identity: ' + path)
    screenshot = root / path / 'screenshot.png'
    if case['screenshot_status'] == 'captured' and not screenshot.is_file():
        raise InvalidBundle('captured screenshot is missing: ' + path)
    if screenshot.is_file():
        with screenshot.open('rb') as stream:
            if stream.read(8) != b'\x89PNG\r\n\x1a\n':
                raise InvalidBundle('invalid PNG signature: ' + path)
    return case


def validate_and_extract(source, extracted):
    if source.stat().st_size > MAX_ZIP:
        raise InvalidBundle('ZIP exceeds archive-size limit')
    try:
        with zipfile.ZipFile(source) as archive:
            entries = zip_entries(archive)
            if 'manifest.json' not in entries or entries['manifest.json'].file_size > MAX_JSON:
                raise InvalidBundle('root manifest.json is missing or oversized')
            manifest = json_document(archive.read('manifest.json'), 'manifest.json')
            if (not isinstance(manifest, dict) or manifest.get('format') != FORMAT
                    or type(manifest.get('version')) is not int or manifest['version'] != 1
                    or not isinstance(manifest.get('bundle_id'), str)
                    or not HEX32.fullmatch(manifest['bundle_id'])
                    or not isinstance(manifest.get('build'), dict)
                    or not isinstance(manifest.get('files'), list)):
                raise InvalidBundle('invalid manifest')
            utc_time(manifest.get('created_at_utc'), 'manifest.created_at_utc')
            build = manifest['build']
            if (any(not isinstance(build.get(key), str) for key in ('version', 'source_commit', 'engine', 'platform'))
                    or type(build.get('offline_tester')) is not bool):
                raise InvalidBundle('invalid build identity')
            expected = {}
            for item in manifest['files']:
                if (not isinstance(item, dict) or not isinstance(item.get('path'), str)
                        or not isinstance(item.get('sha256'), str) or not HEX64.fullmatch(item['sha256'])
                        or type(item.get('size')) is not int or item['size'] < 0):
                    raise InvalidBundle('invalid manifest file entry')
                name = safe_name(item['path'])
                if name.endswith('/') or name == 'manifest.json' or name in expected:
                    raise InvalidBundle('duplicate or invalid manifest path: ' + name)
                expected[name] = item
            if set(expected) != set(entries) - {'manifest.json'}:
                raise InvalidBundle('manifest does not cover exactly the ZIP files')
            extracted.mkdir(mode=0o700)
            for name, item in expected.items():
                info = entries[name]
                if info.file_size != item['size']:
                    raise InvalidBundle('size mismatch: ' + name)
                destination = extracted.joinpath(*name.split('/'))
                destination.parent.mkdir(parents=True, exist_ok=True)
                digest = hashlib.sha256()
                size = 0
                with archive.open(info) as stream, destination.open('xb') as output:
                    for chunk in iter(lambda: stream.read(1024 * 1024), b''):
                        size += len(chunk)
                        if size > item['size'] or size > MAX_FILE:
                            raise InvalidBundle('expanded-size mismatch: ' + name)
                        digest.update(chunk)
                        output.write(chunk)
                if size != item['size'] or digest.hexdigest() != item['sha256']:
                    raise InvalidBundle('hash or size mismatch: ' + name)
                destination.chmod(0o600)
            case_ids = set()
            for name in expected:
                if not name.startswith('cases/'):
                    continue
                parts = name.split('/')
                if len(parts) < 3 or not HEX32.fullmatch(parts[1]):
                    raise InvalidBundle('invalid case path: ' + name)
                case_ids.add(parts[1])
            for case_id in case_ids:
                path = 'cases/' + case_id
                if path + '/case.json' not in expected or path + '/context.json' not in expected:
                    raise InvalidBundle('incomplete case: ' + path)
                validate_case(path, extracted)
            return manifest
    except (zipfile.BadZipFile, EOFError, RuntimeError, OSError) as error:
        raise InvalidBundle('unreadable or corrupt ZIP: ' + str(error)) from error


def file_hash(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(chunk)
    return digest.hexdigest()


def import_bundles(sources, library):
    library = Path(library)
    if library.is_symlink():
        raise ValueError('library must not be a symlink')
    library.mkdir(parents=True, exist_ok=True, mode=0o700)
    bundles = library / 'bundles'
    if bundles.is_symlink():
        raise ValueError('bundles directory must not be a symlink')
    bundles.mkdir(exist_ok=True, mode=0o700)
    prepared = []
    results = []
    seen = {}
    try:
        for source in sources:
            source = Path(source)
            if source.stat().st_size > MAX_ZIP:
                raise InvalidBundle('ZIP exceeds archive-size limit')
            stage = Path(tempfile.mkdtemp(prefix='.incoming-', dir=library))
            prepared.append(stage)
            raw = stage / 'original.zip'
            shutil.copyfile(source, raw)
            raw.chmod(0o600)
            manifest = validate_and_extract(raw, stage / 'files')
            bundle_id = manifest['bundle_id']
            digest = file_hash(raw)
            if bundle_id in seen and seen[bundle_id] != digest:
                raise InvalidBundle('conflicting bundle_id within import: ' + bundle_id)
            if bundle_id in seen:
                results.append({'bundle_id': bundle_id, 'status': 'deduplicated'})
                prepared[-1] = (stage, bundles / bundle_id, 'deduplicated')
                continue
            seen[bundle_id] = digest
            target = bundles / bundle_id
            if target.exists() or target.is_symlink():
                if target.is_symlink() or not (target / 'original.zip').is_file() or file_hash(target / 'original.zip') != digest:
                    raise InvalidBundle('conflicting bundle_id in library: ' + bundle_id)
                results.append({'bundle_id': bundle_id, 'status': 'deduplicated'})
            else:
                results.append({'bundle_id': bundle_id, 'status': 'imported'})
            prepared[-1] = (stage, target, results[-1]['status'])
        committed = []
        try:
            for stage, target, status in prepared:
                if status == 'imported':
                    if target.exists() or target.is_symlink():
                        raise InvalidBundle('bundle_id appeared during import: ' + target.name)
                    stage.rename(target)
                    committed.append(target)
        except Exception:
            for target in committed:
                shutil.rmtree(target)
            raise
        return results
    finally:
        for item in prepared:
            stage = item[0] if isinstance(item, tuple) else item
            if stage.exists():
                shutil.rmtree(stage)


def library_records(library):
    bundles = Path(library) / 'bundles'
    records = []
    bundle_count = 0
    for folder in sorted(bundles.iterdir()) if bundles.exists() else []:
        if not folder.is_dir() or folder.is_symlink():
            continue
        # manifest.json is deliberately not extracted, so validate the preserved original.
        with zipfile.ZipFile(folder / 'original.zip') as archive:
            manifest = json_document(archive.read('manifest.json'), str(folder / 'original.zip'))
        if manifest['bundle_id'] != folder.name:
            raise InvalidBundle('library bundle identity mismatch: ' + folder.name)
        bundle_count += 1
        for case_file in sorted((folder / 'files' / 'cases').glob('*/case.json')) if (folder / 'files' / 'cases').exists() else []:
            case = validate_case('cases/' + case_file.parent.name, folder / 'files')
            records.append({'case': case, 'manifest': manifest, 'folder': folder})
    return records, bundle_count


def label(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')) if isinstance(value, (dict, list)) else str(value)


def task_label(task):
    chapter = str(task.get('chapter_id', '')).strip()
    level = str(task.get('level_id', '')).strip()
    return '/'.join(part for part in (chapter, level) if part) or '首页 / Home'


def build_label(build):
    return ' · '.join((str(build['version']), str(build['source_commit'])[:12], str(build['platform'])))


def link(from_dir, target):
    return html.escape(Path(os.path.relpath(target, from_dir)).as_posix(), quote=True)


def write_private_report(path, body):
    with tempfile.NamedTemporaryFile('w', encoding='utf-8', dir=path.parent,
                                     prefix='.offline-report-', delete=False) as stream:
        temporary = Path(stream.name)
        stream.write(body)
    try:
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def valid_session_event(event):
    if not isinstance(event, dict) or not isinstance(event.get('payload'), dict):
        return False
    sequence = event.get('sequence')
    if (not isinstance(event.get('session_id'), str) or not event['session_id']
            or type(sequence) not in (int, float) or not math.isfinite(sequence)
            or sequence < 0 or sequence != int(sequence)
            or type(event.get('schema_version', 1)) is not int
            or event.get('schema_version', 1) not in (1, 2)
            or not isinstance(event.get('event'), str)):
        return False
    for key in ('source', 'mode', 'visit_id'):
        if key in event and event[key] is not None and not isinstance(event[key], str):
            return False
    payload = event['payload']
    for key in ('visit_id', 'task_key'):
        if key in payload and payload[key] is not None and not isinstance(payload[key], str):
            return False
    if event['event'] in ('visit_time', 'level_complete', 'level_exit') and 'duration_ms' in payload:
        duration = payload['duration_ms']
        if type(duration) not in (int, float) or not math.isfinite(duration) or duration < 0:
            return False
    if event['event'] == 'official_run' and not isinstance(payload.get('result_class', ''), str):
        return False
    if event['event'] == 'modification':
        for key in ('added_wires', 'removed_wires', 'added_components', 'removed_components',
                    'explicit_wire_deletes', 'incident_wire_removals'):
            value = payload.get(key)
            if type(value) is float and not math.isfinite(value):
                return False
    return True


def archived_session_events(library, counts):
    bundles = Path(library) / 'bundles'
    for folder in sorted(bundles.iterdir()) if bundles.exists() else []:
        sessions = folder / 'files' / 'sessions'
        if not folder.is_dir() or folder.is_symlink() or not sessions.is_dir() or sessions.is_symlink():
            continue
        for path in sorted(sessions.glob('session_*.jsonl')):
            if path.is_symlink() or not path.is_file():
                continue
            counts['session_files'] += 1
            with path.open('rb') as stream:
                for line in stream:
                    if not line.strip():
                        continue
                    counts['session_lines'] += 1
                    if len(line) > MAX_JSON:
                        counts['invalid_json_lines'] += 1
                        continue
                    try:
                        event = json.loads(line.decode('utf-8'),
                                           parse_constant=lambda _: (_ for _ in ()).throw(ValueError()))
                    except (UnicodeError, json.JSONDecodeError, ValueError, RecursionError):
                        counts['invalid_json_lines'] += 1
                        continue
                    if not valid_session_event(event):
                        counts['invalid_event_lines'] += 1
                        continue
                    yield event


def write_session_analysis(library, directory):
    script = Path(__file__).with_name('report-playtests.py')
    spec = importlib.util.spec_from_file_location('report_playtests', script)
    reducer = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(reducer)
    counts = {'session_files': 0, 'session_lines': 0, 'invalid_json_lines': 0, 'invalid_event_lines': 0}
    report = reducer.summarize([{'events': archived_session_events(library, counts)}])
    visits = report['visits']
    counts['incomplete_active_visits'] = sum(bool(visit['started'] and not visit['completed']
                                                  and visit['exit'] is None) for visit in visits)
    counts['unknown_duration_visits'] = sum(visit['foreground_ms'] is None for visit in visits)
    counts['duplicate_event_lines'] = report['duplicate_events_ignored']
    counts['ignored_lines_total'] = (counts['invalid_json_lines'] + counts['invalid_event_lines']
                                     + counts['duplicate_event_lines'] + report['malformed_events_ignored'])
    report['offline_archive'] = counts
    report['limitations'].append('Offline archived JSONL may end during a visit; unknown time is null, never zero or abandonment.')
    directory = Path(directory)
    if directory.is_symlink() or directory.resolve().is_relative_to((Path(library) / 'bundles').resolve()):
        raise ValueError('analysis output must be outside archived bundles')
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    write_private_report(directory / 'report.json', json.dumps(report, ensure_ascii=False, indent=2))
    notice = ('<p>Archived session files: ' + str(counts['session_files'])
              + ' · Ignored lines: ' + str(counts['ignored_lines_total'])
              + ' (invalid JSON ' + str(counts['invalid_json_lines'])
              + ', invalid event ' + str(counts['invalid_event_lines'])
              + ', duplicate ' + str(counts['duplicate_event_lines']) + ')'
              + ' · Incomplete active visits: ' + str(counts['incomplete_active_visits'])
              + ' · Unknown duration visits: ' + str(counts['unknown_duration_visits']) + '</p>')
    page = reducer.render(report).replace('</h1>', '</h1>' + notice, 1)
    write_private_report(directory / 'report.html', page)
    return report


def render_report(library, output):
    output = Path(output).absolute()
    if output.resolve().is_relative_to((Path(library) / 'bundles').resolve()):
        raise ValueError('report output must be outside archived bundles')
    records, bundles_count = library_records(library)
    output.parent.mkdir(parents=True, exist_ok=True)
    analysis = write_session_analysis(library, output.parent / 'analysis')
    grouped = defaultdict(list)
    for record in records:
        grouped[record['case']['id']].append(record)
    category_counts = Counter()
    status_counts = Counter()
    capture_errors = 0
    current_records = []
    for versions in grouped.values():
        current = max(versions, key=lambda record: (record['case']['revision'],
                                                       utc_time(record['case']['updated_at_utc'], 'updated_at_utc'),
                                                       utc_time(record['manifest']['created_at_utc'], 'created_at_utc'),
                                                       record['manifest']['bundle_id']))
        category_counts[current['case']['category']] += 1
        status_counts[current['case']['screenshot_status']] += 1
        capture_errors += bool(current['case']['screenshot_error']) or current['case']['screenshot_status'] == 'failed'
        current_records.append(current)
    h = lambda value: html.escape(str(value), quote=True)
    def selector(key, values, prompt):
        return '<label>' + h(prompt) + ' <select id="' + key + '"><option value="">全部 / All</option>' + ''.join(
            '<option value="' + h(value) + '">' + h(value) + '</option>' for value in sorted(values)) + '</select></label>'
    def revision_html(record, current=False):
        case, manifest, folder = record['case'], record['manifest'], record['folder']
        case_dir = folder / 'files' / 'cases' / case['id']
        image = case_dir / 'screenshot.png'
        screenshot = '<a href="' + link(output.parent, image) + '"><img loading="lazy" src="' + link(output.parent, image) + '" alt="screenshot"></a>' if image.is_file() else '<p>截图 / Screenshot: ' + h(case['screenshot_status']) + '</p>'
        error = '<p class="error">截图错误 / Capture error: ' + h(case['screenshot_error']) + '</p>' if case.get('screenshot_error') else ''
        return ('<div class="revision"><p><strong>' + ('当前 / Current' if current else '历史 / History') + '</strong> · '
                + h(case['updated_at_utc']) + ' · rev ' + h(case['revision']) + ' · ' + h(case['status']) + '</p>'
                + '<p class="note">' + h(case['note']) + '</p>' + screenshot + error
                + '<p><a href="' + link(output.parent, case_dir / 'context.json') + '">Context JSON</a> · '
                + '<a href="' + link(output.parent, folder / 'original.zip') + '">Original ZIP</a> · bundle '
                + h(manifest['bundle_id']) + ' · export ' + h(manifest['created_at_utc']) + '</p></div>')
    cards = []
    for case_id, versions in sorted(grouped.items()):
        versions.sort(key=lambda record: (record['case']['revision'],
                                          utc_time(record['case']['updated_at_utc'], 'updated_at_utc'),
                                          utc_time(record['manifest']['created_at_utc'], 'created_at_utc'),
                                          record['manifest']['bundle_id']), reverse=True)
        current = versions[0]
        case = current['case']
        build = build_label(case.get('build', current['manifest']['build']))
        task = task_label(case['task'])
        history = '<details><summary>历史修订 / History (' + str(len(versions) - 1) + ')</summary>' + ''.join(revision_html(version) for version in versions[1:]) + '</details>' if len(versions) > 1 else ''
        cards.append('<article data-category="' + h(case['category']) + '" data-build="' + h(build)
                     + '" data-task="' + h(task) + '"><h2>' + h(case_id) + ' · ' + h(case['category']) + '</h2>'
                     + '<p>Task: ' + h(task) + '<br>Build: ' + h(build) + '<br>Captured: ' + h(case['captured_at_utc']) + '</p>'
                     + revision_html(current, True) + history + '</article>')
    page = ('<!doctype html><html lang="zh"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
            '<meta http-equiv="Content-Security-Policy" content="default-src \'none\'; img-src \'self\' data: file:; style-src \'unsafe-inline\'; script-src \'unsafe-inline\'">'
            '<title>Offline playtest review</title><style>body{font:16px/1.5 system-ui,sans-serif;max-width:1100px;margin:auto;padding:1.5rem;color:#172335;background:#f7f9fc}'
            'article{background:white;border:1px solid #ccd5e2;border-radius:.7rem;padding:1rem;margin:1rem 0}img{max-width:100%;max-height:420px;border:1px solid #ddd}'
            '.revision{border-top:1px solid #ddd;padding-top:.5rem}.note{white-space:pre-wrap}.error{color:#a22}label{display:inline-block;margin:.3rem}input,select{font:inherit;padding:.3rem}</style></head><body>'
            '<h1>离线试玩反馈 / Offline playtest</h1><p><a href="' + link(output.parent, output.parent / 'analysis' / 'report.html')
            + '">会话与任务分析 / Session analysis</a> · Sessions: ' + str(analysis['input_sessions'])
            + ' · Ignored lines: ' + str(analysis['offline_archive']['ignored_lines_total']) + '</p><p>Bundles: ' + str(bundles_count) + ' · Cases: ' + str(len(grouped))
            + ' · Revisions: ' + str(len(records)) + ' · Screenshot status: ' + h(label(dict(status_counts)))
            + ' · Capture errors: ' + str(capture_errors) + '</p><p>Category counts: ' + h(label(dict(category_counts))) + '</p>'
            '<div><label>搜索 / Search <input id="search" type="search"></label>'
            + selector('category', category_counts, '类别 / Category')
            + selector('task', {task_label(record['case']['task']) for record in current_records}, '任务 / Task')
            + selector('build', {build_label(record['case'].get('build', record['manifest']['build'])) for record in current_records}, '版本 / Build')
            + '</div><main>' + ''.join(cards) + '</main><p id="visible-count"></p>'
            '<script>const controls=["search","category","task","build"].map(id=>document.getElementById(id));'
            'function filter(){let [q,c,t,b]=controls.map(x=>x.value.toLocaleLowerCase());let n=0;'
            'for(const card of document.querySelectorAll("article")){const ok=(!q||card.textContent.toLocaleLowerCase().includes(q))'
            '&&(!c||card.dataset.category.toLocaleLowerCase()===c)&&(!t||card.dataset.task.toLocaleLowerCase()===t)'
            '&&(!b||card.dataset.build.toLocaleLowerCase()===b);card.hidden=!ok;if(ok)n++;}'
            'document.getElementById("visible-count").textContent=n+" visible";}controls.forEach(x=>x.addEventListener("input",filter));filter();</script>'
            '</body></html>')
    write_private_report(output, page)
    return {'bundles': bundles_count, 'cases': len(grouped), 'revisions': len(records),
            'capture_errors': capture_errors, 'sessions': analysis['input_sessions'],
            'ignored_session_lines': analysis['offline_archive']['ignored_lines_total']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    importer = sub.add_parser('import', help='validate and archive one or more ZIP exports')
    importer.add_argument('zips', nargs='+', type=Path)
    importer.add_argument('--library', type=Path, required=True)
    reporter = sub.add_parser('report', help='render local HTML from the archive')
    reporter.add_argument('--library', type=Path, required=True)
    reporter.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        result = import_bundles(args.zips, args.library) if args.command == 'import' else render_report(args.library, args.output)
    except (InvalidBundle, OSError, ValueError) as error:
        parser.exit(1, 'offline playtest: ' + str(error) + '\n')
    print(json.dumps(result, ensure_ascii=False, sort_keys=True))


if __name__ == '__main__':
    main()

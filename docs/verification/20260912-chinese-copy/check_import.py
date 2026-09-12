"""Reproduce this bounded import receipt against its recorded source commit."""
import ast
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
manifest = json.loads((HERE / 'import-manifest.json').read_text())
base = manifest['base_commit']
def old(path):
    return subprocess.check_output(['git', 'show', f'{base}:{path}'], cwd=ROOT, text=True)
def now(path):
    return (ROOT / path).read_text()
def catalog(text):
    pairs = re.findall(r'^msgid (".*")\nmsgstr (".*")$', text, re.M)
    result = {ast.literal_eval(k): ast.literal_eval(v) for k, v in pairs}
    assert len(result) == len(pairs), 'Duplicate catalog keys'
    return result
def rows(name):
    result = [json.loads(line) for line in (HERE / name).read_text().splitlines()]
    assert len(result) == len({r['id'] for r in result}) == 82
    return {r['id']: r for r in result}
source, final = rows('source-decisions.jsonl'), rows('final-decisions.jsonl')
assert source.keys() == final.keys()
protected = re.compile(r'%[-+0-9.]*[sdf]|\[\[[^\]]+\]\]|\b[A-Za-z][A-Za-z0-9_]*(?:\+[A-Za-z]+)?\b|\d+(?:/\d+)*')
zh_path, en_path = 'localization/game.zh_CN.po', 'localization/game.en.po'
zh, before = catalog(now(zh_path)), catalog(old(zh_path))
for ident, src in source.items():
    dst = final[ident]
    assert hashlib.sha256(src['audit_baseline_zh'].encode()).hexdigest() == src['baseline_sha256'] == dst['baseline_sha256']
    if not ident.startswith('synthetic:'):
        assert zh[src['key']] == dst['final_zh'], src['key']
        assert Counter(protected.findall(src['audit_baseline_zh'])) == Counter(protected.findall(dst['final_zh'])), src['key']
        assert before[src['key']] == dst['repository_zh'], src['key']
actual = {k: (before.get(k), v) for k, v in zh.items() if before.get(k) != v}
expected = {r['key']: (r['before'], r['after']) for r in manifest['changes']}
assert actual == expected, 'Unrecorded Chinese changes'
assert before.keys() <= zh.keys(), 'Removed catalog keys'
en, en_before = catalog(now(en_path)), catalog(old(en_path))
assert all(en[k] == v for k, v in en_before.items()), 'Existing English changed'
assert en.keys() - en_before.keys() == {'overlap.hub.eyebrow'}
assert en['overlap.hub.eyebrow'] == en['overlap.branch.3']
surfaces = json.loads((HERE / 'title-surfaces.json').read_text())
path = 'src/layout_chapter/layout_catalog.gd'
pattern = r'^const TITLES := .*\n'
assert re.sub(pattern, '', old(path), flags=re.M) == re.sub(pattern, '', now(path), flags=re.M), 'Layout behavior changed'
assert ast.literal_eval(re.search(r'^const TITLES := (.*)$', now(path), re.M)[1]) == list(surfaces['layout_titles'].values())
path = 'src/campaign/task_tree_canvas.gd'
expected_canvas = old(path)
for key, title in surfaces['compact_titles'].items():
    pattern = rf'("{key}":\[)"[^"]+"(,"[^"]+"\])'
    expected_canvas, count = re.subn(pattern, lambda m: m[1] + json.dumps(title, ensure_ascii=False) + m[2], expected_canvas)
    assert count == 1, key
assert now(path) == expected_canvas, 'Canvas behavior or English changed'
path = 'src/ui/prototype_hub.gd'
assert now(path) == old(path).replace('Localization.text(&"overlap.title"), Localization.text(&"overlap.branch.3")', 'Localization.text(&"overlap.title"), Localization.text(&"overlap.hub.eyebrow")')
path = 'src/layout_chapter/layout_chapter.gd'
assert now(path) == old(path).replace(surfaces['layout_header']['before'], surfaces['layout_header']['after'])
assert dict(Counter(r['category'] for r in final.values())) == manifest['counts']
print(json.dumps({'status': 'PASS', 'decisions': len(final), 'changed_po_entries': len(actual), 'layout_titles': 6, 'compact_titles': len(surfaces['compact_titles']), 'existing_english_changes': 0, 'protected_token_changes': 0, 'counts': manifest['counts']}, ensure_ascii=False, indent=2))

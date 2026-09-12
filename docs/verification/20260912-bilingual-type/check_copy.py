"""Check this editorial delta against its recorded source revision."""
import ast,json,re,subprocess
from collections import Counter
from pathlib import Path
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
manifest=json.loads((HERE/'copy-changes.json').read_text())
def parse(text):
 pairs=re.findall(r'^msgid (".*")\nmsgstr (".*")$',text,re.M)
 result={ast.literal_eval(k):ast.literal_eval(v) for k,v in pairs}
 assert len(pairs)==len(result),'Duplicate keys'
 return result
def protected(text):
 return Counter(re.findall(r'%[-+0-9.]*[sdf]|\[\[[^\]]+\]\]|\d+(?:/\d+)*',text))
for locale in ['en','zh_CN']:
 path='localization/game.'+locale+'.po'
 before=parse(subprocess.check_output(['git','show',manifest['base_commit']+':'+path],cwd=ROOT,text=True))
 assert not re.search(r'\\u[0-9a-fA-F]{4}',(ROOT/path).read_text()), 'PO must contain UTF-8 characters, not JSON Unicode escapes'
 after=parse((ROOT/path).read_text())
 assert before.keys()==after.keys(),'Keys were added or removed'
 actual={k:(before[k],after[k]) for k in before if before[k]!=after[k]}
 rows=[r for r in manifest['catalog_changes'] if r['locale']==locale]
 assert actual=={r['key']:(r['before'],r['after']) for r in rows},'Unrecorded edits'
 for row in rows:
  if row['kind']!='title':
   assert protected(row['before'])==protected(row['after']),row['key']
 print(locale+': '+str(len(actual))+' changes, protected values intact')
print('PASS: exact catalog changes, keys, placeholders, links and numeric tokens')

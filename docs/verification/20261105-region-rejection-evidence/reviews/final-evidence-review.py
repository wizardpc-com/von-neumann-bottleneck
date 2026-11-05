from pathlib import Path
from hashlib import sha256
from datetime import datetime, timezone
from collections import Counter
import difflib
import gzip
import importlib.util
import json
import re
import statistics
import subprocess
import sys
sys.dont_write_bytecode = True

ROOT = Path('/Users/yrq/Documents/冯诺伊曼瓶颈')
RECEIPT = ROOT / 'docs/verification/20261105-region-rejection-evidence'
OUT = Path('/private/tmp/vnb-round11-final-evidence-review.json')
result = {'reviewed_at':datetime.now(timezone.utc).isoformat(), 'issues':[], 'checks':[], 'engine_runs':0, 'git_commands':0}

def check(ok, label):
    result['checks'].append({'passed':bool(ok),'label':label})
    if not ok: result['issues'].append(label)

def digest(data): return sha256(data).hexdigest()
def read_json(path): return json.loads(path.read_text())
def typed_dict(value): return {entry['key']:entry['value'] for entry in value['@dictionary']}
def walk(value):
    yield value
    if isinstance(value,dict):
        for child in value.values(): yield from walk(child)
    elif isinstance(value,list):
        for child in value: yield from walk(child)

def load_module(name,path):
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

binding=read_json(RECEIPT/'source-sha256.json')
qa=Path(binding['qa_playable'])
reference=Path(binding['frozen_reference'])
check(len(binding['files'])==1251,'source manifest has1251 entries')
for name,hashes in binding['files'].items():
    for label,root in [('source',ROOT),('qa_playable',qa)]:
        path=root/name
        check(path.is_file() and digest(path.read_bytes())==hashes[label],f'{label} binding: {name}')
check(all(v['source']==v['qa_playable'] for k,v in binding['files'].items() if k!='project.godot'),'all1250 non-settings source/QA entries exact')
settings=(qa/'project.godot').read_text()
stripped='\n'.join(line for line in settings.split('\n') if not line.startswith(('config/use_custom_user_dir=','config/custom_user_dir_name=')))
check(stripped==(ROOT/'project.godot').read_text(),'QA settings differ only by explicit two isolation lines')
check(f'config/custom_user_dir_name="{binding["profile"]}"' in settings,'QA playable profile bound')
ref=read_json(RECEIPT/'invocation-tools/round11-reference.json')
check(len(ref['runtime_files'])==556 and ref['base']==binding['base'],'frozen manifest has556 original base-bound entries')
changed=[]
for name,expected in ref['runtime_files'].items():
    check(digest((reference/name).read_bytes())==expected,'frozen source hash: '+name)
    if digest((ROOT/name).read_bytes())!=expected:changed.append(name)
check(changed==['experiments/representation_region/README.md','experiments/representation_region/model.gd'],'only Region model and README differ within original frozen runtime inventory')
result['source_binding']={'count':len(binding['files']),'frozen_count':len(ref['runtime_files']),'changed_from_frozen':changed,'base':binding['base'],'profile':binding['profile']}

harness=read_json(RECEIPT/'invocation-tools/round11-measured-gd-sha256.json')
check(len(harness)==6,'six measured harness scripts')
for name,expected in harness.items():
    for role,root in [('source',ROOT),('reference',reference),('candidate',qa)]:
        check(digest((root/name).read_bytes())==expected,'identical measured harness: '+role+' '+name)
result['harness_scripts']=harness

candidate=read_json(RECEIPT/'checks/candidate-standard/results.json')
check(candidate['engine']=='4.7.1.stable.official.a13da4feb' and candidate['platform']=='darwin','candidate engine and platform exact')
suites={}
for row in candidate['results']:
    raw=(RECEIPT/'checks/candidate-standard'/row['log']).read_bytes()
    text=raw.decode()
    check(raw==(qa.parent/row['log']).read_bytes(),'original candidate log preserved: '+row['name'])
    check(row['exit']==0 and row['passed'] is True and row['errors']==[],'candidate terminal pass: '+row['name'])
    check(not re.search(r'SCRIPT ERROR|ERROR:|Parse Error|WARNING:|^FAIL:',text,re.M),'complete candidate log clean: '+row['name'])
    check(row['custom_user_dir'].startswith('VonNeumannBottleneckChecks/'),'isolated candidate profile: '+row['name'])
    match=re.search(r'PASS:.*?(\d+) checks\s*[,/]\s*(\d+) failures',text)
    if match:suites[row['name']]=[int(match[1]),int(match[2])]
expected_suites={'test_candidate_journey_review':[45,0],'test_candidate_supports':[54,0],'test_representation_region':[3329,0],'test_representation_region_rejections':[854,0],'test_representation_session':[47,0],'test_representation_workbench_presentation':[9303,0]}
check(suites==expected_suites,'six suite counts exactly match documentation')
check((RECEIPT/'checks/candidate-standard/results.json').read_bytes()==(qa.parent/'results.json').read_bytes(),'candidate result receipt equals original')
result['candidate_suites']=suites
for stamp in ['20261105T121527Z','20261105T122300Z','20261105T123906Z']:
    folder=RECEIPT/'checks'/stamp
    origin=ROOT/'.godot/region-rejection-checks'/stamp
    for p in folder.iterdir():check(p.read_bytes()==(origin/p.name).read_bytes(),'original check artifact preserved: '+stamp+'/'+p.name)
    for row in read_json(folder/'results.json'):
        log=(folder/(row['suite']+'.log')).read_bytes()
        check(digest(log)==row['log_sha256'],'complete log bound: '+stamp+'/'+row['suite'])
        check(row['stopped_for'] is None and row['profile'].startswith('VonNeumannBottleneckChecks/'),'terminal isolated check: '+stamp+'/'+row['suite'])
        check(row['region_model_sha256']==digest(((reference if stamp!='20261105T123906Z' else qa)/'experiments/representation_region/model.gd').read_bytes()),'correct actual Region implementation: '+stamp+'/'+row['suite'])
negative=(RECEIPT/'checks/20261105T122300Z/test_representation_region_rejections.log').read_text()
errors=[line for line in negative.splitlines() if line.startswith('ERROR:')]
categories=Counter()
for line in errors:
    for category in ['no residual execution or storage metrics','no computed output, codec or cache rows','no events or completed scalar result','every remaining typed Trace field retains its fresh default']:
        if category in line:categories[category]+=1
check(len(errors)==252 and len(categories)==4 and set(categories.values())=={63},'old negative has exactly63x4 intended residual-evidence errors')
check('FAIL: representation region rejections 854 checks / 252 failures (63 rejected, 11 delegated, 12 valid boundary cases)' in negative,'old negative reaches exact terminal FAIL marker')
check(not re.search(r'SCRIPT ERROR|Parse Error|WARNING:',negative),'old negative has no parser/runtime/warning failure')
startup=read_json(RECEIPT/'checks/20261105T123906Z/results.json')[0]
check(startup['returncode']==0 and startup['diagnostics']==[] and startup['command'][-2:]==['--quit-after','8'] and '--script' not in startup['command'],'ordinary main-scene headless startup0, no script fixture')
result['negative_categories']=dict(categories)
result['startup']=startup
launcher=ROOT/'.godot/region-evidence-preview-20261105.command'
shell=subprocess.run(['zsh','-n',str(launcher)],capture_output=True,text=True)
check(shell.returncode==0 and not shell.stderr,'preview launcher zsh syntax check')
check(bool(launcher.stat().st_mode&0o111) and str(qa) in launcher.read_text() and '--script' not in launcher.read_text(),'executable normal-preview launcher targets bound QA')

seal=load_module('vnb_review_seal',ROOT/'scripts/benchmarks/computation/record.py')
blobs={}
summary={}
for folder in sorted((RECEIPT/'benchmarks').iterdir()):
    inv=read_json(folder/'invocations.json')[0]
    original=ROOT/'.godot/region-rejection-benchmarks'/folder.name
    for p in folder.iterdir():check(p.read_bytes()==(original/p.name).read_bytes(),'original benchmark artifact preserved: '+folder.name+'/'+p.name)
    raw=gzip.decompress((folder/'workload.json.gz').read_bytes())
    check(digest(raw)==inv['raw_sha256'] and len(raw)==inv['raw_bytes'],'benchmark exact raw byte hash and size: '+folder.name)
    check(inv['profile'].startswith('VonNeumannBottleneckChecks/round11/'),'benchmark profile is task isolated: '+folder.name)
    user_output=Path('/Users/yrq/Library/Application Support')/inv['profile']/'computation-benchmark.json'
    check(raw==user_output.read_bytes(),'archived raw equals original isolated engine output: '+folder.name)
    log=(folder/'workload.log').read_bytes()
    resealed=seal.seal(raw,log,inv['returncode'])
    serialized=(json.dumps(resealed,ensure_ascii=False,allow_nan=False,separators=(',',':'))+'\n').encode()
    check(serialized==gzip.decompress((folder/'workload.sealed.json.gz').read_bytes()),'raw + complete log + actual exit reproduces sealed bytes: '+folder.name)
    check(resealed['display']=='headless' and resealed['samples']==3 and resealed['processor']=='Apple M2' and resealed['host_label']=='yrq-mac-round11','same declared headless host and3 samples: '+folder.name)
    spans=[]
    text=raw.decode()
    decoder=json.JSONDecoder()
    for match in re.finditer(r'"snapshot"\s*:\s*',text):
        value,end=decoder.raw_decode(text,match.end())
        spans.append(text[match.end():end].encode())
        del value
    check(len(spans)==len(resealed['cases']),'complete snapshot spans: '+folder.name)
    cases={}
    for c,span in zip(resealed['cases'],spans):
        check(digest(span)==c['snapshot_sha256'] and len(span)==c['snapshot_bytes'],'full serialized snapshot hash/size: '+folder.name+'/'+c['id'])
        check(len(c['durations_us'])==3 and statistics.median(c['per_call_us'])==c['median_us'],'actual3-sample median: '+folder.name+'/'+c['id'])
        traces=sum(isinstance(x,dict) and x.get('@script')=='res://src/simulation/simulation_trace.gd' for x in walk(c['snapshot']))
        decisions=sum(isinstance(x,dict) and x.get('key')=='accepted' and type(x.get('value')) is bool for x in walk(c['snapshot']))
        cases[c['id']]={'input':c['input'],'bytes':span,'traces':traces,'decisions':decisions,'median_us':c['median_us'],'range_us':[c['min_us'],c['max_us']],'iterations':c['iterations']}
        if c['id']=='workload_rejections':cases[c['id']]['frozen']=c['snapshot']
    blobs[folder.name]=cases
    summary[folder.name]={'returncode':inv['returncode'],'failures':len(resealed['failures']),'raw_bytes':len(raw),'raw_sha256':digest(raw),'cases':{k:{a:b for a,b in v.items() if a not in ['input','bytes','frozen']} for k,v in cases.items()}}
    del resealed
vref=blobs['20261105T122550Z-reference-valid']
vnew=blobs['20261105T123217Z-candidate-valid']
for key in vref:
    a,b=vref[key],vnew[key]
    check(a['bytes']==b['bytes'] and a['input']==b['input'],'complete exact typed input/output evidence: '+key)
    check(a['iterations']==b['iterations'],'same fixed iteration count: '+key)
check(sum(c['traces'] for c in vref.values())==36 and sum(c['decisions'] for c in vref.values())==22,'36 full valid traces and20+2 actual decisions')
dref=blobs['20261105T122734Z-reference-rejection-defect']['workload_rejections']
dnew=blobs['20261105T123341Z-candidate-rejection']['workload_rejections']
a,b=typed_dict(dref['frozen']),typed_dict(dnew['frozen'])
check(a.keys()==b.keys() and len(a)==14,'same14 diagnostic members')
check([k for k in a if a[k]!=b[k]]==['region'],'all13 diagnostic siblings exact')
check(dref['input']==dnew['input'],'complete diagnostic input exact')
fa,fb=a['region']['fields'],b['region']['fields']
check([k for k in fa if fa[k]!=fb[k]]==['expected_value','metrics','result_value'],'only declared Region top-level fields differ')
ma,mb=typed_dict(fa['metrics']),typed_dict(fb['metrics'])
check(ma.keys()==mb.keys() and len(ma)==21,'Region metric key set unchanged21')
changed_metrics=[k for k in ma if ma[k]!=mb[k]]
zero=['total_cycles','request_cycles','transfer_cycles','decode_cycles','consume_cycles','stored_bytes','traffic_bytes','decoded_values','decode_ops','cache_hits','cache_misses','evictions','overfetch_values','peak_cache_bytes']
check(all(mb[k]=={'@int':'0'} for k in zero),'all14 candidate numeric fields exact typed zero')
check(all(mb[k]['@array']==[] for k in ['outputs','expected','blocks','accesses']),'four candidate evidence arrays empty')
check(all(ma[k]==mb[k] for k in ['error','spec','plan']),'Region error and full typed input provenance exact')
result['benchmarks']=summary
result['diagnostic_changed_metrics']=changed_metrics
result['diagnostic_array_types']={k:{'old':ma[k]['element_type'],'new':mb[k]['element_type']} for k in ['outputs','expected','blocks','accesses']}
check(read_json(RECEIPT/'invocation-tools/round11-valid-comparison.json')['passed'] is True,'unmodified strict comparator accepts two valid cases')
strict=read_json(RECEIPT/'invocation-tools/round11-diagnostic-strict-comparison.json')
check(strict['passed'] is False and strict['cases']==[],'strict comparator rejects historical failed diagnostic with no speed ratio')
review=read_json(RECEIPT/'reviews/diagnostic-compare.json')
initial=read_json(RECEIPT/'reviews/diagnostic-initial-checker-failure.json')
check(review['passed'] is True and review['issues']==[],'independent artifact review terminal success')
check(initial['passed'] is False and initial['issues']==['reference: project settings otherwise exact current source'],'independent original blank-line checker failure preserved')

reviewed_docs=['README.md','docs/CURRENT_STATE.md','ARCHITECTURE.md','docs/architecture/simulation.md','docs/development/testing.md','docs/development/COMPUTATION_AUDIT_20261105.md','docs/exec-plans/active/README.md','docs/exec-plans/completed/region-rejection-evidence-20261105.md','docs/README.md','experiments/representation_region/README.md','docs/verification/20261105-region-rejection-evidence/README.md']
result['document_hashes']={name:digest((ROOT/name).read_bytes()) for name in reviewed_docs}
for p in [RECEIPT/'README.md',ROOT/'docs/exec-plans/completed/region-rejection-evidence-20261105.md']:
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text()):
        if '://' in link or link.startswith('#'):continue
        check((p.parent/link.split('#')[0]).exists(),'local evidence link resolves: '+str(p.relative_to(ROOT))+' '+link)
result['passed']=not result['issues']
result['check_count']=len(result['checks'])
OUT.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'passed':result['passed'],'checks':result['check_count'],'issues':result['issues'],'json':str(OUT),'suites':suites,'diagnostic_changed_metrics':changed_metrics},ensure_ascii=False,indent=2))

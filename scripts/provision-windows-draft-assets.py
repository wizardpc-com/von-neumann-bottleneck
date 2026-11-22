#!/usr/bin/env python3
"""Operator helper for the two dedicated, short-lived Windows draft asset secrets."""
import argparse
from contextlib import closing
from http.client import HTTPSConnection, HTTPException
import importlib.util
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import uuid


SCRIPTS = Path(__file__).resolve().parent
SPEC = importlib.util.spec_from_file_location('windows_release', SCRIPTS/'verify-release-windows.py')
WINDOWS = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(WINDOWS)


def gh(args, *, data=None, operation):
    env = {key:value for key,value in os.environ.items() if key!='GH_DEBUG'}
    env.update(GH_HOST='github.com',GH_PROMPT_DISABLED='1')
    result = subprocess.run(['gh',*args],env=env,input=data,text=True,capture_output=True,timeout=45)
    if result.returncode:
        raise RuntimeError(f'GitHub CLI could not {operation}')
    return result.stdout


def asset_redirect(repository, asset_id, token):
    try:
        with closing(HTTPSConnection('api.github.com',timeout=15)) as client:
            client.request('GET',f'/repos/{repository}/releases/assets/{asset_id}',headers={
                'Authorization':'Bearer '+token,
                'Accept':'application/octet-stream',
                'X-GitHub-Api-Version':'2022-11-28',
                'User-Agent':'vnb-draft-package-qa',
            })
            with client.getresponse() as response:
                if response.status!=302:
                    raise RuntimeError(f'GitHub did not issue a single-asset redirect (HTTP {response.status})')
                location=response.getheader('Location','')
    except (OSError, HTTPException):
        raise RuntimeError('Could not obtain the GitHub single-asset redirect') from None
    _, expires = WINDOWS.validate_capability(location,minimum_seconds=180)
    return location, expires


def provision(repository, capabilities):
    names=list(WINDOWS.CAPABILITY_SECRETS.values())
    existing=json.loads(gh(['secret','list','--repo',repository,'--app','actions','--json','name'],
                           operation='check the dedicated Actions secret names'))
    if {r['name'] for r in existing} & set(names):
        raise ValueError('Dedicated draft asset secret names are already in use; no secret was changed')
    created=[]
    try:
        for role,name in WINDOWS.CAPABILITY_SECRETS.items():
            created.append(name)
            gh(['secret','set',name,'--repo',repository,'--app','actions'],data=capabilities[role],
               operation='set '+name)
    except BaseException:
        for name in created:
            try:
                gh(['secret','delete',name,'--repo',repository,'--app','actions'],operation='delete '+name)
            except (RuntimeError,subprocess.TimeoutExpired):
                print(f'Cleanup required for dedicated Actions secret {name}',file=sys.stderr)
        raise


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo',required=True)
    parser.add_argument('--release-id',required=True)
    parser.add_argument('--tag',required=True)
    parser.add_argument('--commit',required=True)
    for role in ('game','test'):
        parser.add_argument('--'+role+'-asset',required=True)
        parser.add_argument('--'+role+'-sha256',required=True)
    parser.add_argument('--provision',action='store_true',
                        help='Create only the two dedicated Actions secrets; default checks eligibility without writing them')
    args=parser.parse_args()
    if os.environ.get('GITHUB_ACTIONS')=='true':
        parser.error('Run this operator helper locally, outside GitHub Actions.')
    repo=WINDOWS.pinned(args.repo,r'[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+','repository')
    release_id=WINDOWS.pinned(args.release_id,r'[1-9][0-9]*','draft ID')
    tag=WINDOWS.pinned(args.tag,r'v[0-9]+\.[0-9]+\.[0-9]+(?:-[A-Za-z0-9.-]+)?','tag')
    commit=WINDOWS.pinned(args.commit,r'[0-9a-f]{40}','source commit')
    release=WINDOWS.gh_get(f'repos/{repo}/releases/{release_id}')
    WINDOWS.verify_draft(repo,release,release_id,tag,commit)
    assets={}
    for role in ('game','test'):
        name=WINDOWS.pinned(getattr(args,role+'_asset'),WINDOWS.ASSET_PATTERN,'asset name')
        digest=WINDOWS.pinned(getattr(args,role+'_sha256').lower(),r'[0-9a-f]{64}','asset SHA-256')
        assets[role]=WINDOWS.asset_identity(release,name,digest)
    if (assets['game']['id']==assets['test']['id'] or assets['game']['sha256']==assets['test']['sha256']):
        raise ValueError('Game and Test require distinct pinned assets')
    token=gh(['auth','token','--hostname','github.com'],operation='read the local gh credential').strip()
    if not token:
        raise RuntimeError('A local GitHub CLI credential that can read the draft is required')
    capabilities={}
    expires={}
    for role,asset in assets.items():
        capabilities[role], end=asset_redirect(repo,asset['id'],token)
        expires[role]=end.isoformat()
    receipt_dir=SCRIPTS.parent/'.godot/windows-release-qa'
    receipt_dir.mkdir(parents=True,exist_ok=True)
    receipt=receipt_dir/f'draft-{release_id}-{uuid.uuid4().hex[:8]}.json'
    WINDOWS.write_json(receipt,{'repository':repo,'release_id':release_id,'tag':tag,'source_commit':commit,
                                'assets':assets,'expires_utc':expires,'secrets':WINDOWS.CAPABILITY_SECRETS,
                                'provisioned':False})
    if args.provision:
        provision(repo,capabilities)
        data=WINDOWS.read_json(receipt)
        data['provisioned']=True
        WINDOWS.write_json(receipt,data)
    print('Dedicated draft capability secrets provisioned.' if args.provision else 'Two draft asset capabilities verified.')
    print('Receipt without credentials: '+str(receipt))
    return 0


if __name__=='__main__':
    try:
        sys.exit(main())
    except (OSError,ValueError,RuntimeError,subprocess.TimeoutExpired) as error:
        print(str(error),file=sys.stderr)
        sys.exit(1)

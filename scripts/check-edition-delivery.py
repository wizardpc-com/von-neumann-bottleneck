#!/usr/bin/env python3
"""Verify four Game/Test desktop packages share one frozen source and content."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def verify_pair(game, test, *, player_release=False):
    roots = [Path(game).resolve(), Path(test).resolve()]
    checker = Path(__file__).with_name('check-candidate-identity.py')
    manifests = []
    for folder, expected in zip(roots, ['game', 'test']):
        subprocess.run([sys.executable, str(checker), str(folder)], check=True)
        manifest = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
        if manifest.get('edition') != expected:
            raise ValueError('Expected ' + expected + ' edition: ' + str(folder))
        if manifest.get('network_feedback_test') or manifest.get('player_feedback_pilot'):
            raise ValueError('Game/Test delivery cannot include a QA or Pilot edition: ' + str(folder))
        if manifest.get('player_release', False) is not player_release:
            raise ValueError('Player release delivery requires --player-release and two player release editions: ' + str(folder))
        if set(manifest['platforms']) != {'Windows', 'macOS'}:
            raise ValueError('Each edition must include both Windows and macOS')
        manifests.append(manifest)
    game_manifest, test_manifest = manifests
    if player_release and game_manifest['test_batch'] != test_manifest['test_batch']:
        raise ValueError('Player release editions must use the same explicit batch')
    for key in ['source_commit', 'engine', 'release_version', 'display_version',
                'content_version', 'content_tasks', 'workspace_versions', 'branding',
                'native_versions']:
        if game_manifest[key] != test_manifest[key]:
            raise ValueError('Edition sources/configurations disagree: ' + key)
    for key in ['windows_template_sha256', 'mac_template_sha256']:
        if game_manifest.get(key) != test_manifest.get(key):
            raise ValueError('Edition export templates disagree: ' + key)
    if not set(game_manifest['save_directories']).isdisjoint(test_manifest['save_directories']):
        raise ValueError('Edition save directories overlap')
    result = {'passed': True, 'source_commit': game_manifest['source_commit'],
            'release_version': game_manifest['release_version'], 'engine': game_manifest['engine'],
            'content_version': game_manifest['content_version'], 'content_count': 60,
            'editions': {manifest['edition']: {'directory': str(folder), 'build_id': manifest['build_id'],
                         'profile': manifest['save_profile'], 'archives': manifest['platforms']}
                         for folder, manifest in zip(roots, manifests)},
            'scope': 'Source/content/profile identity and all archive hashes; not native platform acceptance'}
    if player_release:
        result.update(player_release=True, test_batch=game_manifest['test_batch'])
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('game', type=Path)
    parser.add_argument('test', type=Path)
    parser.add_argument('--player-release', action='store_true', help='Require the public Game and offline capture Test pair')
    args = parser.parse_args()
    print(json.dumps(verify_pair(args.game, args.test, player_release=args.player_release), ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()

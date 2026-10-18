#!/usr/bin/env python3
"""Compile every Luau file and run real logic using the official Luau CLI."""
from pathlib import Path
import os
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def tool(name, variable):
    configured = os.environ.get(variable)
    cached = Path('/workspace/.cloudpop-tools/bin') / name
    found = configured or shutil.which(name) or (str(cached) if cached.exists() else None)
    if not found:
        raise SystemExit(f'{name} is missing. Run bash tools/bootstrap.sh, or set {variable}.')
    return found


def main():
    luau = tool('luau', 'LUAU_BIN')
    compiler = tool('luau-compile', 'LUAU_COMPILE_BIN')
    generated = ROOT / 'tests/.generated'
    generated.mkdir(exist_ok=True)
    try:
        profile_source = (ROOT / 'src/server/ProfileStore.luau').read_text()
        (generated / 'ProfileStoreHarness.luau').write_text(
            'return function(game, script, task, warn, os)\n' + profile_source + '\nend\n')
        server_source = (ROOT / 'src/server/GameServer.server.luau').read_text()
        (generated / 'ServerHarness.luau').write_text(
            'return function(game, workspace, task, Instance, Random, require, script, os)\n' + server_source + '\nend\n')
        workshop_source = (ROOT / 'src/server/Workshop.luau').read_text()
        (generated / 'WorkshopHarness.luau').write_text(
            'return function(game, workspace, Instance, Vector3, Color3, Enum)\n' + workshop_source + '\nend\n')
        client_source = (ROOT / 'src/client/GameClient.client.luau').read_text()
        globals_ = ('game', 'script', 'workspace', 'task', 'Instance', 'require', 'warn',
                    'Color3', 'ColorSequence', 'UDim', 'UDim2', 'Vector2', 'Vector3',
                    'CFrame', 'Enum', 'TweenInfo')
        bindings = '\n'.join(f'local {name} = environment.{name}' for name in globals_)
        (generated / 'ClientHarness.luau').write_text(
            'return function(environment)\n' + bindings + '\n' + client_source + '\nend\n')
        sources = sorted((ROOT / 'src').rglob('*.luau')) + sorted((ROOT / 'tests').rglob('*.luau'))
        for source in sources:
            result = subprocess.run([compiler, '--null', str(source)], cwd=ROOT, capture_output=True, text=True)
            if result.returncode:
                print(result.stdout + result.stderr, file=sys.stderr)
                raise SystemExit(result.returncode)
        print(f'Luau compilation: {len(sources)} files passed', flush=True)
        for spec in sorted((ROOT / 'tests').glob('*.spec.luau')):
            subprocess.run([luau, str(spec)], cwd=ROOT, check=True)
    finally:
        shutil.rmtree(generated)


if __name__ == '__main__':
    main()

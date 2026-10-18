#!/usr/bin/env python3
"""Build Roblox places with Rojo's standard serializer, never handwritten XML."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def find_rojo():
    configured = os.environ.get('ROJO_BIN')
    cache = Path(os.environ.get('CLOUDPOP_TOOLS_DIR', '/workspace/.cloudpop-tools')) / 'bin/rojo'
    executable = configured or shutil.which('rojo') or (str(cache) if cache.exists() else None)
    if not executable:
        raise SystemExit('Rojo is missing. Run python3 tools/install_rojo.py, install Rojo, or set ROJO_BIN.')
    return executable


def build(destination):
    destination = Path(destination).resolve()
    if destination.suffix not in {'.rbxl', '.rbxlx'}:
        raise ValueError('Place output must end with .rbxl or .rbxlx')
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run([find_rojo(), 'build', str(ROOT / 'default.project.json'), '--output', str(destination)],
                   cwd=ROOT, check=True)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix(destination.suffix + '.sha256').write_text(f'{digest}  {destination.name}\n')
    print(f'Packaged {destination} ({destination.stat().st_size:,} bytes)', flush=True)
    return destination


def package_zip(source):
    source = Path(source)
    destination = source.with_name('CloudpopCommons-Studio.zip')
    entry = zipfile.ZipInfo(source.name, date_time=(1980, 1, 1, 0, 0, 0))
    entry.compress_type = zipfile.ZIP_DEFLATED
    entry.external_attr = 0o100644 << 16
    with zipfile.ZipFile(destination, 'w') as archive:
        archive.writestr(entry, source.read_bytes())
    with zipfile.ZipFile(destination) as archive:
        if archive.testzip() is not None or archive.read(source.name) != source.read_bytes():
            raise RuntimeError('Studio ZIP validation failed')
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    destination.with_suffix('.zip.sha256').write_text(f'{digest}  {destination.name}\n')
    print(f'Packaged and verified {destination}', flush=True)
    return destination


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path)
    arguments = parser.parse_args()
    if arguments.output:
        build(arguments.output)
    else:
        # Binary is the recommended download; refresh the older XML link too.
        build(ROOT / 'dist/CloudpopCommons.rbxl')
        build(ROOT / 'dist/CloudpopCommons.rbxlx')
        package_zip(ROOT / 'dist/CloudpopCommons.rbxl')

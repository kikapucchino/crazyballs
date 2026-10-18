#!/usr/bin/env python3
"""Install the pinned upstream Rojo Linux release with TLS and SHA-256 verification."""
import hashlib
import io
import os
from pathlib import Path
import platform
import urllib.request
import zipfile

VERSION = '7.5.1'
ARCHIVE_SHA256 = '0d600df6c4c48a9d09c701d0c2a109c55c2db833cd9766fd7d1e6e2684843d53'
URL = f'https://github.com/rojo-rbx/rojo/releases/download/v{VERSION}/rojo-{VERSION}-linux-x86_64.zip'


def install():
    if platform.system() != 'Linux' or platform.machine() not in {'x86_64', 'AMD64'}:
        raise SystemExit('This cloud installer targets Linux x86_64. Install Rojo from its upstream release for your OS.')
    cache = Path(os.environ.get('CLOUDPOP_TOOLS_DIR', '/workspace/.cloudpop-tools'))
    # Pin the archive's actual bytes, including during repeated installation.
    archive_path = cache / f'rojo-{VERSION}.zip'
    data = archive_path.read_bytes() if archive_path.exists() else None
    if data is None:
        with urllib.request.urlopen(URL, timeout=60) as response:
            data = response.read()
    if hashlib.sha256(data).hexdigest() != ARCHIVE_SHA256:
        raise SystemExit('Rojo archive checksum mismatch. Installation stopped; do not use these bytes.')
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        executable = archive.read('rojo')
    target = cache / 'bin/rojo'
    target.parent.mkdir(parents=True, exist_ok=True)
    archive_path.write_bytes(data)
    target.write_bytes(executable)
    target.chmod(0o755)
    print(f'Installed verified Rojo {VERSION}: {target}')


if __name__ == '__main__':
    install()

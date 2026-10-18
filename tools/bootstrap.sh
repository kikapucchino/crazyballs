#!/usr/bin/env bash
# Install only the official Luau CLI tools, at a reproducible source revision.
set -euo pipefail
cloudpop_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cloudpop_tools="${CLOUDPOP_TOOLS_DIR:-/workspace/.cloudpop-tools}"
cloudpop_revision=9d7748a4f324213a18cb8283fa2a77c330225fa0
mkdir -p "$cloudpop_tools/bin"
if [[ ! -x "$cloudpop_tools/bin/luau" || ! -x "$cloudpop_tools/bin/luau-compile" || ! -f "$cloudpop_tools/revision" || "$(cat "$cloudpop_tools/revision")" != "$cloudpop_revision" ]]; then
  if [[ ! -d "$cloudpop_tools/source/.git" ]]; then
    git clone --no-checkout https://github.com/luau-lang/luau.git "$cloudpop_tools/source"
  fi
  git -C "$cloudpop_tools/source" fetch origin "$cloudpop_revision"
  git -C "$cloudpop_tools/source" checkout --detach "$cloudpop_revision"
  make -C "$cloudpop_tools/source" config=release -j 2 luau luau-compile
  install -m 755 "$cloudpop_tools/source/build/release/luau" "$cloudpop_tools/bin/luau"
  install -m 755 "$cloudpop_tools/source/build/release/luau-compile" "$cloudpop_tools/bin/luau-compile"
  printf '%s\n' "$cloudpop_revision" > "$cloudpop_tools/revision"
fi
cd "$cloudpop_root"
python3 tools/install_rojo.py
LUAU_BIN="$cloudpop_tools/bin/luau" LUAU_COMPILE_BIN="$cloudpop_tools/bin/luau-compile" python3 tools/check.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_place.py

#!/usr/bin/env bash
# Bumps the packages pinned to upstream release binaries (pkgs/omp-bin.nix). The home-ops
# nix-cache builder runs this after `nix flake update` and commits whatever it changes, with
# the lines it prints in the commit message. Also fine to run by hand.
# Needs curl, jq and nix; plain bash for the edit, because the builder's image has no sed.
set -euo pipefail
cd "$(dirname "$0")/.."

file=pkgs/omp-bin.nix
content=$(<"$file")
current=$(grep -o '^  version = "[^"]*";' "$file" | cut -d'"' -f2)
latest=$(curl -fsSL https://api.github.com/repos/can1357/oh-my-pi/releases/latest | jq -r '.tag_name | ltrimstr("v")')
if [ -z "$latest" ] || [ "$latest" = null ]; then
  echo "omp-bin: no latest release found" >&2
  exit 1
fi
[ "$current" = "$latest" ] && exit 0

sum=$(curl -fsSL "https://github.com/can1357/oh-my-pi/releases/download/v$latest/SHA256SUMS.txt" |
  grep ' omp-linux-x64$' | cut -d' ' -f1)
if [ -z "$sum" ]; then
  echo "omp-bin: v$latest has no omp-linux-x64 checksum" >&2
  exit 1
fi
hash=$(nix --extra-experimental-features nix-command hash convert --hash-algo sha256 --to sri "$sum")
old_hash=$(grep -o 'hash = "sha256-[^"]*";' "$file")

content=${content/"version = \"$current\";"/"version = \"$latest\";"}
content=${content/"$old_hash"/"hash = \"$hash\";"}
printf '%s\n' "$content" >"$file"
echo "omp-bin: $current -> $latest"

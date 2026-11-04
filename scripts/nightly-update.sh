#!/usr/bin/env bash
# Bumps the packages pinned to upstream binaries: pkgs/omp-bin.nix (release) and
# pkgs/jellyfin-desktop.nix (CI artifact). The home-ops nix-cache builder runs this after
# `nix flake update` and commits whatever it changes, with the lines it prints in the commit
# message. Also fine to run by hand.
# Needs curl, jq and nix; plain bash for the edits, because the builder's image has no sed.
set -euo pipefail
cd "$(dirname "$0")/.."

nix() { command nix --extra-experimental-features nix-command "$@"; }

# replace FILE OLD NEW: swap the first occurrence of OLD for NEW in FILE.
replace() {
  local content
  content=$(<"$1")
  printf '%s\n' "${content/"$2"/"$3"}" >"$1"
}

update_omp() {
  local file=pkgs/omp-bin.nix current latest sum hash old_hash
  current=$(grep -o '^  version = "[^"]*";' "$file" | cut -d'"' -f2)
  latest=$(curl -fsSL https://api.github.com/repos/can1357/oh-my-pi/releases/latest | jq -r '.tag_name | ltrimstr("v")')
  if [ -z "$latest" ] || [ "$latest" = null ]; then
    echo "omp-bin: no latest release found" >&2
    return 1
  fi
  [ "$current" = "$latest" ] && return 0

  sum=$(curl -fsSL "https://github.com/can1357/oh-my-pi/releases/download/v$latest/SHA256SUMS.txt" |
    grep ' omp-linux-x64$' | cut -d' ' -f1)
  if [ -z "$sum" ]; then
    echo "omp-bin: v$latest has no omp-linux-x64 checksum" >&2
    return 1
  fi
  hash=$(nix hash convert --hash-algo sha256 --to sri "$sum") || return 1
  old_hash=$(grep -o 'hash = "sha256-[^"]*";' "$file")

  replace "$file" "version = \"$current\";" "version = \"$latest\";"
  replace "$file" "$old_hash" "hash = \"$hash\";"
  echo "omp-bin: $current -> $latest"
}

update_jellyfin() {
  local file=pkgs/jellyfin-desktop.nix repo=andrewrabert/jellium-desktop
  local current run latest date version old_version hash old_hash
  current=$(grep -o '^  runId = "[^"]*";' "$file" | cut -d'"' -f2)
  run=$(curl -fsSL "https://api.github.com/repos/$repo/actions/workflows/build-linux-appimage.yml/runs?branch=main&status=success&per_page=1" |
    jq -r '.workflow_runs[0] | "\(.id) \(.created_at[0:10])"')
  read -r latest date <<<"$run"
  if [ -z "$latest" ] || [ "$latest" = null ]; then
    echo "jellyfin-desktop: no successful build-linux-appimage run found" >&2
    return 1
  fi
  [ "$current" = "$latest" ] && return 0

  # `set -e` does not apply inside a function called from `||`, so check every step.
  hash=$(nix store prefetch-file --json \
    "https://nightly.link/$repo/actions/runs/$latest/linux-appimage-x86_64.zip" | jq -r .hash)
  if [ -z "$hash" ] || [ "$hash" = null ]; then
    echo "jellyfin-desktop: could not fetch the artifact of run $latest" >&2
    return 1
  fi
  old_hash=$(grep -o 'hash = "sha256-[^"]*";' "$file")
  old_version=$(grep -o '^  version = "[^"]*";' "$file")
  version="unstable-$date"

  replace "$file" "runId = \"$current\";" "runId = \"$latest\";"
  replace "$file" "$old_hash" "hash = \"$hash\";"
  replace "$file" "$old_version" "  version = \"$version\";"
  echo "jellyfin-desktop: run $current -> $latest ($version)"
}

# Run both even if one fails, then report the failure.
status=0
update_omp || status=1
update_jellyfin || status=1
exit "$status"

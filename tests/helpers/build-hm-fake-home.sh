#!/usr/bin/env bash
# tests/zsh-home-manager.bats が読む home-manager の生成物を、偽の HOME 向けにビルドする。
# bats の中から nix build を呼ぶと、Claude Code の sandbox が nix daemon の socket を止めるので分けている
set -euo pipefail

dotfile_dir="$(cd "$(dirname "$0")/../.." && pwd)"
readonly dotfile_dir
out_dir="$dotfile_dir/tmp/hm-fake-home"
readonly out_dir

mkdir -p "$out_dir"
nix build --impure --no-write-lock-file -o "$out_dir/result" \
  --file "$dotfile_dir/tests/fixtures/hm-fake-home.nix" \
  --argstr flakeRef "git+file://$dotfile_dir" \
  --argstr home "$out_dir/home"

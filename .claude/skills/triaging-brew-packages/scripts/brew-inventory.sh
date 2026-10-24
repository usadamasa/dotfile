#!/usr/bin/env bash
# brew に入っているもの (formula と cask) を全量採取し、振り分けの材料を JSON と markdown で出す
# (triaging-brew-packages skill の手順 1)。判断はしない。
#
# brew info --json=v2 --installed を 1 回、nix eval を 1 回だけ呼ぶ (formula ごとに brew uses を呼ぶと分単位になる)。
# 直接の依存元は brew info の dependencies を逆引きして出す (brew uses --installed は推移的な依存元を返す)。
# nix は sandbox の中から daemon に届かないので、task brew:inventory から呼ぶ (home/status.sh と同じ)
set -euo pipefail

usage() {
  printf 'usage: %s [--repo DIR] [--repos-root DIR] [--hooks-dir DIR] [--out DIR]\n' "$0" >&2
}

repo=$(cd "$(dirname "$0")/../../../.." && pwd)
repos_root="$HOME/src/github.com/usadamasa"
hooks_dir="$HOME/src/github.com/usadamasa/claude-config/shared/hooks"
out=""
while [ $# -gt 0 ]; do
  case $1 in
    --repo) repo=$2; shift 2 ;;
    --repos-root) repos_root=$2; shift 2 ;;
    --hooks-dir) hooks_dir=$2; shift 2 ;;
    --out) out=$2; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
out=${out:-$repo/tmp}

for cmd in brew jq nix; do
  if ! command -v "$cmd" >/dev/null; then
    printf '%s が見つからない\n' "$cmd" >&2
    exit 1
  fi
done
if [ ! -f "$repo/Brewfile" ]; then
  printf 'Brewfile が無い: %s\n' "$repo" >&2
  exit 1
fi

mkdir -p "$out"
brew_json="$out/brew-info.json"
nix_json="$out/brew-inventory-nixpkgs.json"
inventory_json="$out/brew-inventory.json"
inventory_md="$out/brew-inventory.md"

# grep の exit 1 (一致なし) は正常。2 以上 (ファイルが読めない等) だけ失敗にする
grep_or_empty() {
  local rc=0
  grep "$@" || rc=$?
  if [ "$rc" -gt 1 ]; then
    printf 'grep に失敗した (%d): %s\n' "$rc" "$*" >&2
    exit 1
  fi
}

# --- 1. brew ---------------------------------------------------------------------------------
if ! HOMEBREW_NO_ANALYTICS=1 HOMEBREW_NO_AUTO_UPDATE=1 brew info --json=v2 --installed > "$brew_json"; then
  printf 'brew info に失敗した\n' >&2
  exit 1
fi
if ! err=$(jq empty "$brew_json" 2>&1); then
  printf 'brew info の出力が JSON でない: %s\n' "$err" >&2
  exit 1
fi

# --- 2. nixpkgs の同名 attr --------------------------------------------------------------------
# flake.lock の nixpkgs を見る。同名 attr が無いだけで「nixpkgs に無い」とは限らない (bats-core → bats など)。
# 別名の当たりは SKILL.md の表
names_json=$(jq -c '[.formulae[].name]' "$brew_json")
# shellcheck disable=SC2016 # ${n} は nix の式で、bash に展開させない
apply=$(printf '%s %s' \
  'pkgs: map (n: let ok = builtins.tryEval (pkgs.${n}.version or null); in { name = n; found = pkgs ? ${n}; version = if ok.success then ok.value else null; darwin = if pkgs ? ${n} then (builtins.tryEval (pkgs.lib.meta.availableOn { system = "aarch64-darwin"; } pkgs.${n})).value or null else null; })' \
  "(builtins.fromJSON ''${names_json}'')")
if ! nix eval --json --inputs-from "$repo" 'nixpkgs#legacyPackages.aarch64-darwin' --apply "$apply" > "$nix_json"; then
  printf 'nix eval に失敗した (sandbox の中なら task brew:inventory から呼ぶ)\n' >&2
  exit 1
fi

# --- 3. リポジトリ側の材料 ---------------------------------------------------------------------
# devShell を持つ repo: repos_root 直下の各 repo と、採取対象のリポジトリ自身の flake.nix
flakes_list="$out/brew-inventory-flakes.txt"
for f in "$repos_root"/*/flake.nix "$repo/flake.nix"; do
  if [ -f "$f" ]; then
    printf '%s\n' "$f"
  fi
done | sort -u > "$flakes_list"
flakes=()
while IFS= read -r f; do
  flakes+=("$f")
done < "$flakes_list"

# direnv の外から参照される場所: このリポジトリの設定・Taskfile・home-manager と、claude-config の global hook
consumer_paths=()
for p in "$repo/config" "$repo/home" "$repo/.zshenv" "$repo/Taskfile.yml" "$hooks_dir"; do
  if [ -e "$p" ]; then
    consumer_paths+=("$p")
  fi
done

extra='{"devshell_repos":{},"consumer_refs":{}}'
while IFS= read -r name; do
  repos_json='[]'
  if [ "${#flakes[@]}" -gt 0 ]; then
    repos_json=$(grep_or_empty -lwF -e "$name" -- "${flakes[@]}" \
      | while IFS= read -r f; do
          if [ -n "$f" ]; then
            basename "$(dirname "$f")"
          fi
        done \
      | jq -R -s 'split("\n") | map(select(length > 0)) | sort')
  fi

  refs_json='[]'
  if [ "${#consumer_paths[@]}" -gt 0 ]; then
    refs_json=$(grep_or_empty -rnwF -e "$name" -- "${consumer_paths[@]}" \
      | cut -d: -f1,2 \
      | while IFS= read -r ref; do
          if [ -n "$ref" ]; then
            printf '%s\n' "${ref#"$repo/"}"
          fi
        done \
      | jq -R -s 'split("\n") | map(select(length > 0))')
  fi

  extra=$(printf '%s' "$extra" | jq --arg n "$name" --argjson r "$repos_json" --argjson c "$refs_json" \
    '.devshell_repos[$n] = $r | .consumer_refs[$n] = $c')
done < <(jq -r '.formulae[].name' "$brew_json")

# /opt/homebrew を直書きしている設定 (git の pager など)。tests と worktree の写し、Brewfile 自身、作業メモは除く
homebrew_refs_json=$(grep_or_empty -rn --exclude-dir=.git --exclude-dir=tmp --exclude-dir=.direnv --exclude-dir=.claude \
    --exclude-dir=tests --exclude=Brewfile --exclude=bootstrap.sh --exclude=PLAN.md -e /opt/homebrew -- "$repo" \
  | cut -d: -f1,2 \
  | while IFS= read -r ref; do
      if [ -n "$ref" ]; then
        printf '%s\n' "${ref#"$repo/"}"
      fi
    done \
  | jq -R -s 'split("\n") | map(select(length > 0)) | sort')

# --- 4. まとめる -------------------------------------------------------------------------------
generated_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
jq -n \
  --slurpfile brew "$brew_json" \
  --slurpfile nix "$nix_json" \
  --argjson extra "$extra" \
  --argjson homebrew_refs "$homebrew_refs_json" \
  --rawfile brewfile "$repo/Brewfile" \
  --arg generated_at "$generated_at" '
  ($brew[0]) as $b
  | ($nix[0] | map({(.name): .}) | add // {}) as $n
  | ($brewfile | split("\n")) as $lines
  | ([ $lines[] | capture("^\\s*brew \"(?<n>[^\"]+)\"") | .n ]) as $declared_formulae
  | ([ $lines[] | capture("^\\s*cask \"(?<n>[^\"]+)\"") | .n ]) as $declared_casks
  | {
      generated_at: $generated_at,
      formulae: [ $b.formulae[] | . as $f | {
        name,
        full_name,
        tap,
        version: (.installed[0].version // .versions.stable),
        declared: (($declared_formulae | index($f.name)) != null or ($declared_formulae | index($f.full_name)) != null),
        installed_on_request: (.installed[0].installed_on_request // false),
        installed_as_dependency: (.installed[0].installed_as_dependency // false),
        deps: (.dependencies // []),
        dependents: ([ $b.formulae[] | select((.dependencies // []) | index($f.name)) | .name ] | sort),
        nixpkgs: (($n[$f.name] // {found: false, version: null, darwin: null}) | {found, version, darwin}),
        devshell_repos: ($extra.devshell_repos[$f.name] // []),
        consumer_refs: ($extra.consumer_refs[$f.name] // [])
      } ] | sort_by(.name),
      casks: [ $b.casks[] | . as $c | {
        token,
        name: (.name | if type == "array" then .[0] else . end),
        version,
        auto_updates: (.auto_updates // false),
        tap,
        declared: (($declared_casks | index($c.token)) != null)
      } ] | sort_by(.token),
      homebrew_path_refs: $homebrew_refs
    }' > "$inventory_json"

jq -r '
  def dash: if length == 0 then "-" else join(", ") end;
  def yn: if . then "✓" else "-" end;
  def nixcol: if .found then (.version // "?") + (if .darwin == false then " (darwin ✗)" else "" end) else "無し (同名 attr)" end;
  def refs: if length == 0 then "-" else "\(length) 件 (\(.[0]))" end;
  "# brew の採取 (\(.generated_at))",
  "",
  "読み方と振り分けは .claude/skills/triaging-brew-packages/SKILL.md。依存元は直接のものだけ (推移的な依存元ではない)。",
  "",
  "## formula (\(.formulae | length))",
  "",
  "| name | 版 | Brewfile | on_request | 直接の依存 | 直接の依存元 | nixpkgs (同名 attr) | devShell を持つ repo | direnv の外の参照 |",
  "|---|---|---|---|---|---|---|---|---|",
  (.formulae[] | "| \(.name) | \(.version) | \(.declared | yn) | \(.installed_on_request | yn) | \(.deps | dash) | \(.dependents | dash) | \(.nixpkgs | nixcol) | \(.devshell_repos | dash) | \(.consumer_refs | refs) |"),
  "",
  "## cask (\(.casks | length))",
  "",
  "| token | 名前 | 版 | auto_updates | Brewfile |",
  "|---|---|---|---|---|",
  (.casks[] | "| \(.token) | \(.name) | \(.version) | \(.auto_updates | yn) | \(.declared | yn) |"),
  "",
  "## リポジトリ内の /opt/homebrew の参照 (\(.homebrew_path_refs | length))",
  "",
  (.homebrew_path_refs[] | "- \(.)")
' "$inventory_json" > "$inventory_md"

printf '%s\n%s\n' "$inventory_json" "$inventory_md"

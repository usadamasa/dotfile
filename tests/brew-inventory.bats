#!/usr/bin/env bats
# .claude/skills/triaging-brew-packages/scripts/brew-inventory.sh のテスト。
# brew と nix は tests/helpers/brew-inventory-mocks のモックに差し替え、fixture の JSON から採取結果を組み立てる。
# リポジトリと devShell を持つ repo 群は BATS_TEST_TMPDIR に作る

SCRIPT="$BATS_TEST_DIRNAME/../.claude/skills/triaging-brew-packages/scripts/brew-inventory.sh"
MOCKS="$BATS_TEST_DIRNAME/helpers/brew-inventory-mocks"
FIXTURES="$BATS_TEST_DIRNAME/fixtures/brew-inventory"

setup() {
  export MOCK_LOG="$BATS_TEST_TMPDIR/calls.log"
  : > "$MOCK_LOG"
  export MOCK_BREW_INFO="$FIXTURES/brew-info.json"
  export MOCK_BREW_TAP_INFO="$FIXTURES/tap-info.json"
  export MOCK_NIX_EVAL="$FIXTURES/nix-eval.json"

  # 採取対象のリポジトリ。Brewfile に alpha と font-example だけ宣言し、config に /opt/homebrew の参照を 1 つ置く
  REPO="$BATS_TEST_TMPDIR/repo"
  mkdir -p "$REPO/config/git" "$REPO/.claude/worktrees/wt/config/git" "$REPO/tmp"
  printf 'brew "alpha"\ncask "font-example"\ntap "someone/tap"\n' > "$REPO/Brewfile"
  printf '[pager]\n  log = /opt/homebrew/share/git-core/contrib/diff-highlight/diff-highlight | less\n' > "$REPO/config/git/config"
  cp "$REPO/config/git/config" "$REPO/.claude/worktrees/wt/config/git/config"
  printf 'plugins=(gamma)\n' > "$REPO/config/zshrc"
  printf 'devShells = [ gamma ];\n' > "$REPO/flake.nix"

  # devShell を持つ別 repo 群
  REPOS="$BATS_TEST_TMPDIR/repos"
  mkdir -p "$REPOS/one" "$REPOS/two"
  printf 'packages = [ beta gamma ];\n' > "$REPOS/one/flake.nix"
  printf 'packages = [ ];\n' > "$REPOS/two/flake.nix"

  # global hook 群
  HOOKS="$BATS_TEST_TMPDIR/hooks"
  mkdir -p "$HOOKS"
  printf 'command -v beta || exit 0\n' > "$HOOKS/beta-on-write.sh"

  OUT="$BATS_TEST_TMPDIR/out"
}

run_inventory() {
  PATH="$MOCKS:$PATH" run bash "$SCRIPT" --repo "$REPO" --repos-root "$REPOS" --hooks-dir "$HOOKS" --out "$OUT"
}

@test "brew info と brew tap-info と nix eval を 1 回ずつ呼び、brew には HOMEBREW_NO_ANALYTICS=1 を渡す" {
  run_inventory
  [ "$status" -eq 0 ]

  run grep -c 'CALLED: brew info --json=v2 --installed (HOMEBREW_NO_ANALYTICS=1)' "$MOCK_LOG"
  [ "$output" = "1" ]
  run grep -c 'CALLED: brew tap-info --json --installed (HOMEBREW_NO_ANALYTICS=1)' "$MOCK_LOG"
  [ "$output" = "1" ]
  run grep -c 'CALLED: nix eval' "$MOCK_LOG"
  [ "$output" = "1" ]
}

@test "Brewfile に宣言されているかを formula と cask に付ける" {
  run_inventory
  [ "$status" -eq 0 ]

  [ "$(jq -r '.formulae[] | select(.name == "alpha") | .declared' "$OUT/brew-inventory.json")" = "true" ]
  [ "$(jq -r '.formulae[] | select(.name == "gamma") | .declared' "$OUT/brew-inventory.json")" = "false" ]
  [ "$(jq -r '.casks[] | select(.token == "font-example") | .declared' "$OUT/brew-inventory.json")" = "true" ]
  [ "$(jq -r '.casks[] | select(.token == "selfupdating-app") | .declared' "$OUT/brew-inventory.json")" = "false" ]
}

@test "直接の依存元を brew info の dependencies から逆引きする" {
  run_inventory
  [ "$status" -eq 0 ]

  [ "$(jq -c '.formulae[] | select(.name == "beta") | .dependents' "$OUT/brew-inventory.json")" = '["alpha"]' ]
  [ "$(jq -c '.formulae[] | select(.name == "alpha") | .dependents' "$OUT/brew-inventory.json")" = '[]' ]
  [ "$(jq -r '.formulae[] | select(.name == "beta") | .installed_on_request' "$OUT/brew-inventory.json")" = "false" ]
}

@test "cask の depends_on.formula も逆引きし、formula の依存元と分けて付ける" {
  run_inventory
  [ "$status" -eq 0 ]

  [ "$(jq -c '.formulae[] | select(.name == "beta") | .cask_dependents' "$OUT/brew-inventory.json")" = '["cli-app"]' ]
  [ "$(jq -c '.formulae[] | select(.name == "alpha") | .cask_dependents' "$OUT/brew-inventory.json")" = '[]' ]
  [ "$(jq -c '.casks[] | select(.token == "cli-app") | .deps' "$OUT/brew-inventory.json")" = '["beta"]' ]
  grep -q '^| beta | .* | alpha, cli-app (cask) |' "$OUT/brew-inventory.md"
}

@test "nixpkgs の同名 attr の有無・版・darwin 対応を付ける" {
  run_inventory
  [ "$status" -eq 0 ]

  [ "$(jq -c '.formulae[] | select(.name == "alpha") | .nixpkgs' "$OUT/brew-inventory.json")" = '{"found":true,"version":"1.1.0","darwin":true}' ]
  [ "$(jq -r '.formulae[] | select(.name == "gamma") | .nixpkgs.found' "$OUT/brew-inventory.json")" = "false" ]
}

@test "devShell に持つ repo と、direnv の外で使う箇所 (hook / config / Taskfile) を名前ごとに引く" {
  run_inventory
  [ "$status" -eq 0 ]

  [ "$(jq -c '.formulae[] | select(.name == "gamma") | .devshell_repos' "$OUT/brew-inventory.json")" = '["one","repo"]' ]
  [ "$(jq -c '.formulae[] | select(.name == "alpha") | .devshell_repos' "$OUT/brew-inventory.json")" = '[]' ]
  # beta は hook が command -v で探す。gamma は config/zshrc から参照される。flake.nix の参照は consumer に数えない
  jq -r '.formulae[] | select(.name == "beta") | .consumer_refs[]' "$OUT/brew-inventory.json" | grep -q 'hooks/beta-on-write.sh:1'
  jq -r '.formulae[] | select(.name == "gamma") | .consumer_refs[]' "$OUT/brew-inventory.json" | grep -q 'config/zshrc:1'
  run jq -r '.formulae[] | select(.name == "gamma") | .consumer_refs[]' "$OUT/brew-inventory.json"
  [[ "$output" != *flake.nix* ]]
}

@test "tap ごとに Brewfile の宣言と、その tap から入っている formula / cask を付け、API だけの official tap は除く" {
  run_inventory
  [ "$status" -eq 0 ]

  # homebrew/core は installed: false (JSON API から入れている) なので tap の一覧に出さない
  [ "$(jq -c '[.taps[].name]' "$OUT/brew-inventory.json")" = '["someone/tap","unused/tap"]' ]
  [ "$(jq -r '.taps[] | select(.name == "someone/tap") | .declared' "$OUT/brew-inventory.json")" = "true" ]
  [ "$(jq -c '.taps[] | select(.name == "someone/tap") | .installed_formulae' "$OUT/brew-inventory.json")" = '["gamma"]' ]
  [ "$(jq -c '.taps[] | select(.name == "someone/tap") | .provides' "$OUT/brew-inventory.json")" = '{"formulae":2,"casks":0}' ]
  [ "$(jq -r '.taps[] | select(.name == "unused/tap") | .declared' "$OUT/brew-inventory.json")" = "false" ]
  [ "$(jq -c '.taps[] | select(.name == "unused/tap") | .installed_formulae' "$OUT/brew-inventory.json")" = '[]' ]
  [ "$(jq -c '.taps[] | select(.name == "unused/tap") | .installed_casks' "$OUT/brew-inventory.json")" = '[]' ]
}

@test "リポジトリ内の /opt/homebrew 参照を集め、tmp と worktree の写しは除く" {
  run_inventory
  [ "$status" -eq 0 ]

  [ "$(jq -r '.homebrew_path_refs | length' "$OUT/brew-inventory.json")" = "1" ]
  [ "$(jq -r '.homebrew_path_refs[0]' "$OUT/brew-inventory.json")" = "config/git/config:2" ]
}

@test "読む用の markdown も出す" {
  run_inventory
  [ "$status" -eq 0 ]

  grep -q '^| alpha |' "$OUT/brew-inventory.md"
  grep -q '^| gamma |' "$OUT/brew-inventory.md"
  grep -q 'selfupdating-app' "$OUT/brew-inventory.md"
  grep -q '^| unused/tap |' "$OUT/brew-inventory.md"
  grep -q 'config/git/config:2' "$OUT/brew-inventory.md"
}

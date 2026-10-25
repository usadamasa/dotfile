---
name: triaging-brew-packages
description: brew の中身を全量点検し、home-manager・devShell・brew に振り分けて移行プランを立てるときに使う。
---

# triaging-brew-packages

brew に入っている formula・cask・tap を振り分け、PR 単位の移行プランを `./tmp/brew-migration-plan.md` に書く。
この skill の中では `brew uninstall` も `task hm:switch` も打たない。どちらもプランの適用手順に書く。

## 手順

### 1. 採取する

リポジトリ直下を cwd にして、この字面のまま打つ (APPENDIX「なぜ字面のまま打つか」)。

```bash
.claude/skills/triaging-brew-packages/scripts/brew-inventory.sh
```

`./tmp/brew-inventory.md` を読み、細部は `./tmp/brew-inventory.json` を引く。

- 直接の依存元: formula と cask (`(cask)` 付き) の直接の依存元。`brew uses --installed` で打ち直さない
  (推移的で、cask を出さない)
- nixpkgs が「無し (同名 attr)」: 名前が違うだけのことが多い。`nix search --inputs-from . nixpkgs <名前の一部>` で
  1 回引いてから「nixpkgs に無い」と決める (`bats-core` は `bats`、`ca-certificates` は `cacert`)
- devShell を持つ repo: `flake.nix` を formula 名と formula の実行ファイル名 (json の `executables`) で引いたもの。
  attr 名がどちらとも違うものは拾えない
- direnv の外の参照: formula 名だけで引く。`git` `zsh` のような一般語は件数が膨らむ。json の `consumer_refs` で中身を見る

### 2. formula と cask を振り分ける

Brewfile に無いものも含めて全部を、表の上から見て最初に当たった行へ振り分ける。

| 振り分け | 条件 | 例 |
|---|---|---|
| 依存で残る | on_request でなく、直接の依存元がある | `pcre2` `ncurses` |
| 自己更新に任せる | cask の `auto_updates` が ✓、または Brewfile 末尾のコメントの一覧にある | ChatGPT、claude-code |
| brew に残す | (a) nixpkgs に無いか darwin ✗、(b) ログインシェル、(c) cask のフォント、(d) nixpkgs 版が macOS 同梱のコマンドを接頭辞なしで隠し、`-prefixed` の attr も無い、(e) 設定が `/opt/homebrew` を直書きしていて、同じ PR で直さない | `git-now` `font-cica` `git` |
| devShell へ | direnv の外の参照が無く、使う repo が `flake.nix` を持つ (無ければその repo に devShell を足す) | `bats-core` `yamllint` `uv` |
| home.packages へ | direnv の外で要る (global hook が `command -v` で探す、`config/zsh/` から呼ぶ、日常の CLI) | `shellcheck` `jq` `gh` |
| 消すだけ | 依存元も参照も devShell の repo も無く、用途が無いと分かる | `editorconfig` |
| 用途を聞く | 上のどれにも当たらない on_request の leaf | `mysql-client` `gcc` |

次の 2 つは表より優先する。

- 別の端末で使うもの (`aqua`) は `home.packages` へ入れ、その行に「別の端末で使う」とコメントを付ける
- `zsh-autosuggestions` `zsh-syntax-highlighting` は `home.packages` に入れない (`home/zsh.nix` が読む)

### 3. tap を振り分ける

| 振り分け | 条件 |
|---|---|
| untap | その tap から入っているものが無い |
| 最後の 1 つを移す PR で untap | その tap から入っているものが、全部「brew に残す」以外に振り分けられた |
| 残す | その tap から入っているものに「brew に残す」がある |

### 4. 既存の issue を引く

```bash
gh issue list --repo usadamasa/dotfile --state open --search "<formula 名>"
```

issue がある formula は、プランでその issue を指す。

### 5. プランを書く

`./tmp/brew-migration-plan.md` の冒頭に振り分けごとの対象の表を、末尾に「用途を聞く」の一覧を置く。
間に PR を、1 本に数個ずつ依存の少ない順に並べる。依存を共有するものは、依存元が全部そろう PR を最後に置く。

各 PR には、移す・消すもの、版 (brew → nixpkgs)、`/opt/homebrew` を指す設定の置き換え、
作り直すもの (brew の python / node に乗った pipx・`uv tool`・npm の global) と、次の適用手順を書く。

```sh
task hm:switch
whence -a <cmd>              # nix の profile が先に当たるか
brew uninstall <formula...>  # on_request のものは autoremove で消えない
brew untap <tap>             # tap の最後の 1 つを移す PR だけ。Brewfile の tap 行も同じ PR で消す
brew autoremove --dry-run
brew autoremove
task status                  # home-manager の PATH 行が ✓ になれば 1 単位の終わり
```

適用手順には次の注記を添える。

- 適用する端末で採取し直してから打つ。依存元は端末ごとに違う
- 認証を持つツールは、uninstall の前に新しい版から認証が見えるか確かめる
- `brew uninstall` は sandbox の中では動かず、cask は `sudo` を聞くことがある。普通のターミナルで打ってもらう
- `required by <cask>` で拒否されたら、採取で `(cask)` と出た依存元を先に片付ける
- 同じ formula の版が 2 つ入っていることがある。`brew list --versions <formula>` で確かめる
- gcloud は `gcloud components list --only-local-state` の component を全部 `google-cloud-sdk.withExtraComponents` に書く。
  cask を消した後に `/opt/homebrew/share/google-cloud-sdk` を手で消す

### 6. 報告する

プランのパス、振り分けの件数、「用途を聞く」の一覧を返す。issue への反映は指示があってから行う。

## 推奨しない形

| 見つけたら | 置き換え先 |
|---|---|
| 用途の分からないものを「消すだけ」にする | 「用途を聞く」に置く。消すのはユーザーの判断 |
| devShell にあるツールを home.packages にも入れる | devShell だけに置く。direnv の外の参照があるときだけ home.packages |
| GitHub の issue を振り分けの規則にする | 規則はこの skill の表と Brewfile のコメントが持つ |
| `brew bundle cleanup` で Brewfile との差を出す | `--dry-run` が無く、Brewfile に無いものを消しに行く。差は採取の Brewfile 列から読む |

## APPENDIX: なぜ字面のまま打つか

script の中の `nix eval` は daemon の socket に繋ぐので、sandbox の中では動かない。script はプロジェクトの
`.claude/settings.json` の `sandbox.excludedCommands` に載せてあり、照合は字面で行われる。`./` を付けたり
`bash` を前に置いたりすると sandbox の中で動き、`nix eval` が落ちる。

---
name: triaging-brew-packages
description: brew の中身を全量点検し、home-manager・devShell・brew に振り分けて移行プランを立てるときに使う。
---

# triaging-brew-packages

brew に入っているもの (Brewfile に無い leaf と tap も含む) を 1 つずつ、home-manager / devShell / brew に残す / 消す の
どれかへ振り分け、PR 単位の移行プランを書く。成果物はプラン (レポート) になる。`brew uninstall` `brew untap`
`task hm:switch` はこの skill の手順では打たず、各 PR の適用手順に書く。

## 手順

### 1. 採取する

リポジトリ直下 (または worktree) を cwd にして、この字面のまま打つ。
brew を 2 回 (`info` と `tap-info`)、nix を 1 回呼び、1 分かからない。

```bash
.claude/skills/triaging-brew-packages/scripts/brew-inventory.sh
```

`./tmp/brew-inventory.md` (読む用) と `./tmp/brew-inventory.json` (引く用) ができる。script はプロジェクトの
`.claude/settings.json` の `sandbox.excludedCommands` に載せてある。上の字面で呼んだときだけ sandbox の外で動く
(APPENDIX「なぜ sandbox の外で動かすか」)。`./` を付けたり `bash` を前置きしたりすると sandbox の中で動き、
`nix eval` が daemon に届かず落ちる。

列の読み方は次のとおり。

| 列 | 意味 | 読み違えやすい点 |
|---|---|---|
| Brewfile | `Brewfile` に `brew "<name>"` / `cask "<token>"` があるか | 無い (-) ものは「brew に入っているのに宣言が無い」leaf か依存。宣言するか、移すか、消すかのどれかにする |
| on_request | `installed_on_request` | ✓ は手で入れたもの。`brew autoremove` は触らないので、消すなら `brew uninstall` を打つ |
| 直接の依存元 | `brew info` の `dependencies` を逆引きしたもの | 直接だけ。`brew uses --installed` の出力 (推移的) とは数が違う。逆引きは installed の全 formula を見ているので、`-` なら `brew uses` を打ち直さなくてよい。「依存元 -」でも on_request なら残る |
| nixpkgs (同名 attr) | flake.lock の nixpkgs に同じ名前の attr があるか、その版、aarch64-darwin で使えるか | 「無し (同名 attr)」は名前が違うだけのことが多い。下の「nixpkgs の名前を引く」を済ませてから「nixpkgs に無い」と書く。`?` は attr が derivation でない (set) |
| devShell を持つ repo | `~/src/github.com/usadamasa/*/flake.nix` にその名前がある repo | worktree から実行すると worktree 名も混ざる |
| direnv の外の参照 | `config/` `home/` `.zshenv` `Taskfile.yml` と claude-config の `shared/hooks/` で名前が出る箇所 | `git` `zsh` `vim` のような一般語は件数が膨らむ。json の `consumer_refs` で中身を見る |

tap の表は `brew tap-info --json --installed` から作る。
JSON API で入れている `homebrew/core` `homebrew/cask` は `installed: false` なので載らない。

| 列 | 意味 | 読み違えやすい点 |
|---|---|---|
| Brewfile | `Brewfile` に `tap "<name>"` があるか | 無くても、その tap の formula を `brew "<tap>/<name>"` で宣言していれば `brew bundle` が tap を足す。宣言の有無はその行も見る |
| この tap から入っている formula / cask | `brew info` の `tap` がこの tap のもの | 両方 `-` なら、tap を残す理由が無い (`brew update` のたびに fetch されるだけ) |
| tap が持つ数 | tap が提供する formula / cask の数 | 何の tap だったかを思い出す手がかり。json の `provides` |

#### nixpkgs の名前を引く

brew の formula 名と nixpkgs の attr 名は、同じツールでも次のようにずれる。「無し (同名 attr)」が出たら、
名前の一部で 1 回だけ検索して、attr の有無と版を確かめる。

```bash
nix search --inputs-from . nixpkgs <name の一部>
```

- brew の `-core` `-cli` のような接尾辞は nixpkgs に無いことが多い (`bats-core` は `bats`)
- `@<version>` 付きの formula は、nixpkgs では版なしの attr か、他の formula の依存にしか現れない
- ライブラリは `lib` の有無や `-` と `_` が違う
- CA bundle やコンパイラのように、同じ物を別の名前で持つものがある (`ca-certificates` は `cacert`)
- 自作ツールや個人の tap のものは無いのが普通で、GitHub release か `go install` で入れる

`nix search` は attr 名の一部を見せるだけで、`<name>` がそのまま attr として存在するかは採取の列 (`nix eval`) のほうが
確かになる。検索の結果だけで「無い」と書かない。

### 2. 振り分ける

各 formula について表を上から順に見て、最初に当たった行を採る。条件は採取結果から読める形で書いてある。

| 振り分け | 条件 | 例 |
|---|---|---|
| 依存で残る (触らない) | on_request でなく、直接の依存元がある | `pcre2` `gmp` `ncurses`。依存元が全部消えれば `brew autoremove` が消す |
| 自己更新に任せる | cask で `auto_updates` ✓、または Brewfile 末尾のコメントの一覧にある | ChatGPT、JetBrains Toolbox、claude-code。Brewfile にも home-manager にも書かない |
| brew に残す | 次のどれか: (a) nixpkgs に無い (名前を引いた上で)、(b) ログインシェル、(c) cask のフォント、(d) nixpkgs 版が macOS 同梱のコマンドを接頭辞なしで隠す、(e) リポジトリの設定が `/opt/homebrew` のパスを直書きしていて、その変更を同じ PR に入れない | (a) `git-now`、(b) `zsh`、(c) `font-cica`、(d) `coreutils` (nixpkgs 版は `ls` `cp` を接頭辞なしで置く。移すなら `coreutils-prefixed`)、(e) `git` (pager の diff-highlight) |
| devShell へ (brew からは消すだけ) | direnv の外の参照が無く、使う repo が全部 `flake.nix` を持つ。「devShell を持つ repo」に無い repo で使うなら、その repo の devShell に足す | `bats-core` `editorconfig-checker` `yamllint` `go-task` `uv` |
| home.packages へ | direnv の外で要る。claude-config の global hook が `command -v` で探す、`config/zsh/` から呼ぶ、日常の CLI | `shellcheck` (hook が探す)、`jq` `tig` `wget` `gh` `ghq`。nixpkgs 版が darwin ✗ なら brew に残す |
| 消すだけ | 直接の依存元が無く、direnv の外の参照も devShell の repo も無く、リポジトリと `~/src` の設定からも用途が無いと分かる。言語ランタイムは中身 (`~/.local/share/pyenv/versions` など) が空なら | `editorconfig`、Python を 1 つも入れていない `pyenv` |
| 用途を聞く | 上のどれにも当たらない on_request の leaf。コンパイラ・DB クライアント・言語ランタイムのように、どのプロジェクトが使うか採取からは分からないもの | `mysql-client`、`gcc`。プランには「未決」として残し、「消す (要確認)」とは書かない。消すのはユーザーの判断 |

振り分けの境目になる決めごとは次のとおり。

- devShell にあるツールは home-manager に重ねて入れない。各 repo の devShell が持つ
- ただし direnv の外から探されるものは home-manager に入れる。claude-config の global hook は `command -v` で探し、
  無ければ黙って skip するので、hook が使うツールは direnv の外に要る
- 採取は今の端末 1 台しか見ない。この端末で使う形跡が無くても、別の端末で使うものは「消すだけ」にせず
  `home.packages` へ入れる。`home/` の設定は全端末で共有されるため。該当するのは `aqua`。
  `home/packages.nix` のその行に「別の端末で使う」とコメントを付け、次の採取で消す側へ振り分けないようにする
- oh-my-zsh の plugin (`zsh-autosuggestions` `zsh-syntax-highlighting` `zsh-completions`) は 3 つで 1 つの PR にする。
  `home.packages` に入れ、`.zshrc` で profile の `share/` から source し、`_setup-shell` の git clone を消すところまでが
  1 セット。1 つだけ拾って別建てにしない

tap は formula と cask の振り分けが決まった後に見る。

| 振り分け | 条件 |
|---|---|
| untap (消すだけ) | その tap から入っている formula / cask が 1 つも無く、Brewfile にも宣言が無い |
| 最後の 1 つを移す PR で untap | その tap から入っているものが、全部「home.packages へ」「devShell へ」「消すだけ」のどれかに振り分けられた。その PR の適用手順に `brew untap` を書き、Brewfile の `tap` 行も同じ PR で消す |
| 残す | その tap から入っているものに「brew に残す」がある |

### 3. 既存の決めごとと突き合わせる

「残す」の根拠は、Brewfile 先頭のコメント、`home/packages.nix` のコメント、この skill の表が持つ。
GitHub の issue から規則を取りに行かない。

formula ごとに open の issue があるかだけを引く。

```bash
gh issue list --repo usadamasa/dotfile --state open --search "<formula 名>"
```

既に issue がある formula は、プランでその issue を指し、段取りを重ねて書かない。

### 4. プランを書く

`./tmp/brew-migration-plan.md` に Write で書く。PR 1 本に数個、依存の少ない順。
同じ依存 (`openssl@4` など) を共有するものは、依存元が全部そろう PR を最後に置く。

```markdown
# brew の移行プラン (<採取日>)

採取: ./tmp/brew-inventory.md。振り分けの基準: triaging-brew-packages skill。

## 全体 (<formula 数> formula、<cask 数> cask、<tap 数> tap)

| 振り分け | 対象 |
|---|---|
| home.packages へ | ... |
| devShell へ (消すだけ) | ... (repo ごとに、足す devShell) |
| 消すだけ | ... |
| brew に残す | ... (理由の記号 a〜e) |
| 依存で残る | ... |
| 自己更新に任せる | ... |
| 用途を聞く | ... |
| untap | ... (何も入っていない tap と、最後の 1 つを移す PR の番号) |

## PR 1: <対象>

- 移す / 消す: ...
- 版: brew x.y → nixpkgs x.y (戻るならそう書く。darwin ✗ なら brew に残す)
- brew 側の道連れ: `brew autoremove` で消えるもの、on_request で残るもの (`brew uninstall` を書く)
- 設定の変更: `/opt/homebrew` のパスを指す行があればその置き換え先 (同じ PR で)
- 作り直すもの: pipx の venv、`uv tool`、npm の global など、brew の python / node に乗っていたもの
- 適用手順:
  ```sh
  task hm:switch
  brew uninstall <formula...>
  brew untap <tap>          # その tap から入っているものが無くなるとき
  brew autoremove --dry-run
  brew autoremove
  task status
  ```

## PR 2: ...

## 未決 (ユーザーに聞く)

- <formula>: 用途が分からない。残すなら Brewfile に宣言する
```

`task status` の `home-manager の PATH` 行が ✓ になるところまでが 1 単位
(APPENDIX「なぜ brew uninstall までが 1 単位か」)。

### 5. 報告する

プランのパスと、振り分けの件数、未決の一覧を返す。issue への反映は、指示があってから行う
(`gh issue edit --body-file` / `gh issue create --body-file`。本文は `./tmp` に Write)。

## 推奨しない形

| 見つけたら | 置き換え先 |
|---|---|
| formula ごとに `brew uses --installed` を打つ | 採取の「直接の依存元」を読む。1 回数秒 × 70 で分単位になり、しかも推移的 |
| 「同名 attr 無し」をそのまま「nixpkgs に無い」と書く | 「nixpkgs の名前を引く」を 1 回だけ |
| nixpkgs の有無と版を `nix search` だけで決める | 採取の nixpkgs 列 (flake.lock の nixpkgs を `nix eval` した値) を読む。`nix search` は attr 名の一部しか出さず、`gcc` が `gcc-unwrapped` しか無いように見える |
| GitHub の issue を読んで振り分けの規則にする | 規則はこの skill の表と Brewfile のコメントが持つ。issue は formula ごとの有無だけ引く |
| devShell にあるツールを home.packages にも入れる | devShell へ。direnv の外の参照があるときだけ home.packages |
| `brew uninstall` を `task hm:switch` より先に書く | switch → uninstall の順。間が空くとコマンドが無くなる |
| `brew autoremove` だけで消えると書く | on_request のものは残る。`brew uninstall` を明記する |
| brew の python / node に乗った venv をそのままにする | `pipx reinstall-all` など作り直しを適用手順に入れる |
| Brewfile に無い leaf を見なかったことにする | 全部プランに載せる。宣言する・移す・消す・聞く のどれか |
| tap から入っている最後の formula を消して tap を残す | 同じ PR の適用手順に `brew untap` を書く。残った tap は `brew update` のたびに fetch され、何の tap だったかも忘れる |
| `brew bundle cleanup` で tap や leaf の差を出す | `--dry-run` は無く、素で打つと Brewfile に無いものを消しに行く。差は採取の Brewfile 列と tap の表から読む |
| 用途不明のものを「消すだけ」にする | 「用途を聞く」に置く。消すのはユーザーの判断 |

## APPENDIX: なぜ sandbox の外で動かすか

`nix eval` は daemon の socket に繋ぐ。sandbox の中の bash からは `Operation not permitted` になる。
そのため script をプロジェクトの `.claude/settings.json` の `sandbox.excludedCommands` に載せてある。
照合は字面で行われ、パターンと同じ相対パスで、前置きもパイプも無しに呼んだときだけ外で動く
(sandbox-troubleshooting skill)。

## APPENDIX: なぜ直接の依存元か

`brew uses --installed` は推移的な依存元を返す (`ca-certificates` に `coreutils` が出る)。
プランの順序に要るのは「これを消したら何が孤児になるか」で、それは直接の依存の逆引きで分かる。
`brew info --json=v2 --installed` 1 回で全 formula の `dependencies` が取れるので、逆引きは手元で済む。

## APPENDIX: なぜ devShell と home-manager を分けるか

リポジトリの開発ツール (bats、lint) は flake.lock で版が CI と揃う。home-manager に重ねて入れると、
direnv の外で古い版が使われたり、`task status` の PATH 行が devShell の実体を「別の実体」と見たりする。
一方 claude-config の global hook はどの repo でも `command -v` で探し、無ければ黙って skip するので、
hook が使うツールは direnv の外に要る。

## APPENDIX: なぜ brew uninstall までが 1 単位か

`config/zsh/.zprofile` が nix の profile を `/opt/homebrew/bin` より前に置くので、brew 版が残っても
使われはしない。ただし `brew upgrade` で更新だけ続き、Brewfile と実体がずれる。だから brew 版を消すところまでを
1 単位にする。`task status` の PATH 行は、`.zprofile` を経ていないシェルなどで brew の実体が前に
来ているものを列挙する。消した後にこの行が ✓ であることを、単位の終わりの確認に使う。

---
name: triaging-brew-packages
description: brew の中身を全量点検し、home-manager・devShell・brew に振り分けて移行プランを立てるときに使う。
---

# triaging-brew-packages

brew に入っているもの (Brewfile に無い leaf も含む) を 1 つずつ home-manager / devShell / brew に残す / 消す に
振り分け、PR 単位の移行プランを書く。成果物はプラン (レポート) で、`brew uninstall` も `task hm:switch` も
この skill の手順では打たない (それは各 PR の適用手順に書く)。

## 手順

### 1. 採取する

リポジトリ直下 (または worktree) を cwd にして打つ。brew と nix を 1 回ずつ呼び、1 分かからない。

```bash
task brew:inventory
```

`./tmp/brew-inventory.md` (読む用) と `./tmp/brew-inventory.json` (引く用) ができる。script は
`.claude/skills/triaging-brew-packages/scripts/brew-inventory.sh` で、直接呼ぶと sandbox の中で nix が daemon に
届かない (APPENDIX「なぜ task 経由か」)。

列の読み方:

| 列 | 意味 | 読み違えやすい点 |
|---|---|---|
| Brewfile | `Brewfile` に `brew "<name>"` / `cask "<token>"` があるか | 無い (-) ものは「brew に入っているのに宣言が無い」leaf か依存。宣言するか、移すか、消すかのどれかにする |
| on_request | `installed_on_request` | ✓ は手で入れたもの。`brew autoremove` は触らないので、消すなら `brew uninstall` を打つ |
| 直接の依存元 | `brew info` の `dependencies` を逆引きしたもの | 直接だけ。`brew uses --installed` の出力 (推移的) とは数が違う。「依存元 -」でも on_request なら残る |
| nixpkgs (同名 attr) | flake.lock の nixpkgs に同じ名前の attr があるか、その版、aarch64-darwin で使えるか | 「無し (同名 attr)」は名前が違うだけのことが多い。下の別名の表を見てから「nixpkgs に無い」と書く。`?` は attr が derivation でない (`rust` は set) |
| devShell を持つ repo | `~/src/github.com/usadamasa/*/flake.nix` にその名前がある repo | worktree から実行すると worktree 名も混ざる |
| direnv の外の参照 | `config/` `home/` `.zshenv` `Taskfile.yml` と claude-config の `shared/hooks/` で名前が出る箇所 | `git` `zsh` `vim` のような一般語は件数が膨らむ。json の `consumer_refs` で中身を見る |

nixpkgs の別名 (brew の名前 → nixpkgs の attr):

| brew | nixpkgs | 備考 |
|---|---|---|
| `bats-core` | `bats` | |
| `ca-certificates` | `cacert` | `etc/ssl/certs/ca-bundle.crt`。#153 |
| `clang-format` | `clang-tools` | |
| `gnu-getopt` | `getopt` | |
| `grep` | `gnugrep` | devShell の stdenv に入っている |
| `jpeg-turbo` | `libjpeg_turbo` | |
| `json-c` | `json_c` | |
| `kubernetes-cli` | `kubectl` | |
| `openssl@3` `openssl@4` | `openssl` | 他の formula の依存。単体で移す対象ではない |
| `rust` | `rustup` または `cargo` `rustc` | `rust` は set |
| `webp` | `libwebp` | |
| `zlib-ng-compat` | `zlib-ng` | |
| `git-now` | 無い | 本当に無い例 |
| `crit` `herdr` | 無い | 自作ツール。GitHub release か `go install` |

表に無い名前は `nix search --inputs-from . nixpkgs <name>` を 1 回だけ試す。

### 2. 振り分ける

formula ごとに上から順に当て、最初に当たった行にする。条件は採取結果から読める形で書いてある。

| 振り分け | 条件 | 例 (決めた PR / issue) |
|---|---|---|
| 依存で残る (触らない) | on_request でなく、直接の依存元がある | `pcre2` `gmp` `ncurses`。依存元が全部消えれば `brew autoremove` が消す |
| 自己更新に任せる | cask で `auto_updates` ✓、または Brewfile 末尾のコメントの一覧にある | ChatGPT、JetBrains Toolbox、claude-code。Brewfile にも home-manager にも書かない |
| brew に残す | 次のどれか: (a) nixpkgs に無い (別名の表を見た上で)、(b) ログインシェル、(c) cask のフォント、(d) nixpkgs 版が macOS 同梱のコマンドを接頭辞なしで隠す、(e) リポジトリの設定が `/opt/homebrew` のパスを直書きしていて、その変更を同じ PR に入れない | (a) `git-now`、(b) `zsh`、(c) `font-cica`、(d) `coreutils` (#105 制約 7)、(e) `git` の pager (#105 制約 6) |
| devShell へ (brew からは消すだけ) | direnv の外の参照が無く、使う repo が全部 `flake.nix` を持つ。「devShell を持つ repo」に無い repo で使うなら、その repo の devShell に足す | `bats-core` `editorconfig-checker` `yamllint` (#152)、`go-task` (#147)、`uv` (#152) |
| home.packages へ | direnv の外で要る。claude-config の global hook が `command -v` で探す、`config/zsh/` から呼ぶ、日常の CLI | `shellcheck` (#152 の hook)、`jq` `tig` `wget` `gh` `ghq` (#140 #149 #151 #152)。nixpkgs 版が darwin ✗ なら brew に残す |
| 消すだけ | 直接の依存元が無く、direnv の外の参照も devShell の repo も無く、リポジトリと `~/src` の設定からも用途が無いと分かる。言語ランタイムは中身 (`~/.local/share/pyenv/versions` など) が空なら | `editorconfig` (#152)、`pyenv` (#154) |
| 用途を聞く | 上のどれにも当たらない on_request の leaf。コンパイラ・DB クライアント・言語ランタイムのように、どのプロジェクトが使うか採取からは分からないもの | `mysql-client` (#154)、`gcc`。プランには「未決」として残し、「消す (要確認)」とは書かない。消すのはユーザーの判断 |

振り分けの境目になる 2 つの判断は、#147 と #152 で決まっている。

- devShell にあるツールは home-manager に重ねて入れない。各 repo の devShell が持つ (`go-task` の決め方)
- ただし direnv の外から探されるものは home-manager に入れる (`shellcheck` は global hook が `command -v` し、無ければ黙って skip する)

### 3. 既存の決めごとと突き合わせる

```bash
gh issue view 105 --repo usadamasa/dotfile --json body --jq '.body'
gh issue list --repo usadamasa/dotfile --state open --search "brew OR Brewfile OR home-manager"
```

#105 の「制約」と「Brew に残すもの」、Brewfile 先頭のコメントが「残す」の根拠を持つ。既に issue がある formula
(`ca-certificates` の #154 など) はプランでその issue を指し、段取りを重ねて書かない。

#105 の Phase に既に載っているものは、その Phase の単位でまとめる。`zsh-autosuggestions` `zsh-syntax-highlighting`
(`zsh-completions` も同じ brew leaf) は Phase 3 案 A で、`.zshrc` の source 行と `_setup-shell` の git clone の削除と
1 つの PR になる。1 つだけ拾って別建てにしない。

### 4. プランを書く

`./tmp/brew-migration-plan.md` に Write で書く。PR 1 本に数個、依存の少ない順。
同じ依存 (`openssl@4` など) を共有するものは、依存元が全部そろう PR を最後に置く。

```markdown
# brew の移行プラン (<採取日>)

採取: ./tmp/brew-inventory.md。振り分けの基準: triaging-brew-packages skill。

## 全体 (<formula 数> formula、<cask 数> cask)

| 振り分け | 対象 |
|---|---|
| home.packages へ | ... |
| devShell へ (消すだけ) | ... (repo ごとに、足す devShell) |
| 消すだけ | ... |
| brew に残す | ... (理由の記号 a〜e) |
| 依存で残る | ... |
| 自己更新に任せる | ... |
| 用途を聞く | ... |

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
  brew autoremove --dry-run
  brew autoremove
  task status
  ```

## PR 2: ...

## 未決 (ユーザーに聞く)

- <formula>: 用途が分からない。残すなら Brewfile に宣言する
```

適用手順の形は PR #149 〜 #153 と同じにする。`task status` の `home-manager の PATH` 行が ✓ になるところまでが
1 単位 (#105 制約 3)。

### 5. 報告する

プランのパスと、振り分けの件数、未決の一覧を返す。issue #105 の表や新しい issue への反映は、指示があってから
(`gh issue edit --body-file` / `gh issue create --body-file`。本文は `./tmp` に Write)。

## 推奨しない形

| 見つけたら | 置き換え先 |
|---|---|
| formula ごとに `brew uses --installed` を打つ | 採取の「直接の依存元」を読む。1 回数秒 × 70 で分単位になり、しかも推移的 |
| 「同名 attr 無し」をそのまま「nixpkgs に無い」と書く | 別名の表 → `nix search` の順で 1 回だけ確かめる |
| nixpkgs の有無と版を `nix search` だけで決める | 採取の nixpkgs 列 (flake.lock の nixpkgs を `nix eval` した値) を読む。`nix search` は attr 名の一部しか出さず、`gcc` が `gcc-unwrapped` しか無いように見える。sandbox の中で `nix eval` が止まるなら `task brew:inventory` |
| devShell にあるツールを home.packages にも入れる | devShell へ (#147)。direnv の外の参照があるときだけ home.packages |
| `brew uninstall` を `task hm:switch` より先に書く | switch → uninstall の順。間が空くとコマンドが無くなる |
| `brew autoremove` だけで消えると書く | on_request のものは残る。`brew uninstall` を明記する (#154 の `openssl@3`) |
| brew の python / node に乗った venv をそのままにする | `pipx reinstall-all` など作り直しを適用手順に入れる (#152) |
| Brewfile に無い leaf を見なかったことにする | 全部プランに載せる。宣言する・移す・消す・聞く のどれか |
| 用途不明のものを「消すだけ」にする | 「用途を聞く」に置く。消すのはユーザーの判断 |

## APPENDIX: なぜ task 経由か

`nix eval` は daemon の socket に繋ぐ。sandbox の中の bash からは `Operation not permitted` になり、
`task` は sandbox の外で動く (`excludedCommands`)。`home/status.sh` と同じ理由。

## APPENDIX: なぜ直接の依存元か

`brew uses --installed` は推移的な依存元を返す (`ca-certificates` に `coreutils` が出る)。
プランの順序に要るのは「これを消したら何が孤児になるか」で、それは直接の依存の逆引きで分かる。
`brew info --json=v2 --installed` 1 回で全 formula の `dependencies` が取れるので、逆引きは手元で済む。

## APPENDIX: なぜ devShell と home-manager を分けるか

リポジトリの開発ツール (bats、lint) は flake.lock で版が CI と揃う。home-manager に重ねて入れると、
direnv の外で古い版が使われたり、`task status` の PATH 行が devShell の実体を「別の実体」と見たりする (#150)。
一方 claude-config の global hook はどの repo でも `command -v` で探し、無ければ黙って skip するので、
hook が使うツールは direnv の外に要る (#152 の `shellcheck`)。

## APPENDIX: なぜ brew uninstall までが 1 単位か

`config/zsh/.zprofile` が nix の profile を `/opt/homebrew/bin` より前に置くので (#142)、brew 版が残っても
使われはしない。ただし `brew upgrade` で更新だけ続き、Brewfile と実体がずれる。`task status` の PATH 行は
brew の実体が前に来ているものを列挙するので、✓ になるまでが単位 (#105 制約 3)。

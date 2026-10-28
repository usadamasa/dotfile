---
name: auditing-path
description: ログインシェルの PATH を棚卸しするとき、PATH に entry を足す・消す・並べ替えるとき、起動のしかたでコマンドの解決先が変わるときに使う。
---

# auditing-path

ログインシェルの PATH の entry ごとに、どのファイルのどの行で足したかと、起動のしかたによる並びの差を点検する。

## 手順

### 1. 採取する

リポジトリ直下を cwd にして打つ。

```bash
bash ${CLAUDE_SKILL_DIR}/scripts/path-origins.sh
```

`## clean` と `## nested` の 2 つの表が出る。列は「順位、entry、最初に足した file:line、(存在しない)」。

- clean: 環境を持ち込まない新しい端末のログインシェル (launchd の PATH から始める)
- nested: 今の環境から入れ子で起動した `zsh -l`。Claude Code の Bash や、端末の中で打った `zsh -l` がこれに当たる

出所は clean の表で読む。nested は親から PATH を継ぐので、ほとんどが `(起動前の環境)` になる。

### 2. 出所をリポジトリの行に結びつける

| 出所 | 足している場所 |
|---|---|
| `~/.config/zsh/.zprofile:<行>` | `config/zsh/zprofile` (home-manager が前置きを足すので行番号はずれる。entry の字面で引く) |
| `nix-daemon.sh` | `home/zsh.nix` の `envExtra` が読む nix の installer の script |
| `~/.config/zsh/.zshenv:<行>` | `home/zsh.nix` の `envExtra` (ログインシェルを通らない zsh 向けに `~/.local/bin` を足す) |
| `hm-session-vars.sh` | `home.sessionPath`。使わない (APPENDIX「なぜ zprofile で足すか」) |
| `/etc/zprofile` | `path_helper` が `/etc/paths` と `/etc/paths.d/*` から足す。リポジトリの外 |
| `(起動前の環境)` | clean では launchd の PATH |

### 3. 点検する

- `(存在しない)` で出所がリポジトリの行なら、その行を消すか、ディレクトリを作るツールがまだ使われているかを確かめる。
  リポジトリの外 (`/etc/paths.d` など) は対象にしない
- `config/zsh/zprofile` が足す entry は、clean と nested で同じ順に並び、どちらでも `/usr/bin` より前にある
- nested の後ろにある `/nix/store/…`・`.direnv/bin`・アプリが足したディレクトリは、親の環境 (direnv、端末アプリ) から
  来たものなので点検の対象にしない
- 最後に `task status` の「home-manager の PATH」行が ✓ になることを確かめる

## PATH に entry を足す

`config/zsh/zprofile` の `brew shellenv` と nix の profile より後ろで、`export PATH="<dir>:$PATH"` を足す。
後ろに書いた行ほど前に来るので、優先したいものを後ろに書く。今の並びは前から順に次のとおり。

1. 自分で入れるツールの置き場 (`~/.claude/bin`、`~/.local/bin`、npm・go・cargo の global install 先)
2. nix の profile (home-manager の版を macOS 同梱と brew より優先する)
3. brew
4. `path_helper` が並べるシステムの entry

GUI アプリが起動する `zsh -c` (ログインシェルでない) でも要る entry は、`home/zsh.nix` の `envExtra` にも
「無いときだけ足す」形で書く。並びは zprofile が決めるので、envExtra 側では位置を気にしない。

足した後は `task hm:switch` を打ち、新しい端末と入れ子の `zsh -l` の両方で採取し直す。

## 推奨しない形

| 見つけたら | 置き換え先 |
|---|---|
| `home.sessionPath` に entry を足す | `config/zsh/zprofile` に足す |
| 存在しないディレクトリを `[[ -d … ]]` のガードで残す | 使っていないなら行ごと消す |
| `export PATH="$PATH:<dir>"` で末尾に足す | 前に置けない理由 (同名のコマンドを隠したくない) があるときだけにする |

## APPENDIX: なぜ zprofile で足すか

`home.sessionPath` は `hm-session-vars.sh` が足し、export されるガード変数で 1 シェルに 1 回しか読まれない。
ログインシェルでは `/etc/zprofile` の `path_helper` が `/etc/paths` の entry を前へ並べ直すので、入れ子の
`zsh -l` では `hm-session-vars.sh` が読み直されず、足した entry が `/usr/bin` の後ろに回ったままになる。
`config/zsh/zprofile` は `path_helper` の後に毎回読まれ、`typeset -U path PATH` で重複を落としながら前に置き直す。

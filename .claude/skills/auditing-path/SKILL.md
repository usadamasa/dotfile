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
出所が home-manager の生成物 (`~/.config/zsh/` 配下など) なら、行番号はリポジトリとずれるので entry の字面で引く。

### 2. 点検する

- `(存在しない)` で出所がリポジトリの行なら、その行がまだ要るかを確かめる。リポジトリの外 (`/etc/paths.d` など) は対象にしない
- リポジトリが足す entry が、clean と nested で同じ順に並ぶか (APPENDIX「なぜ起動のしかたで並びが変わるか」)
- nested の後ろにある `/nix/store/…`・`.direnv/bin`・アプリが足したディレクトリは、親の環境 (direnv、端末アプリ) から
  来たものなので点検の対象にしない
- `task status` の「home-manager の PATH」行が ✓ になるか

entry を足す・消す・並べ替えた後は `task hm:switch` を打ち、採取し直す。

## APPENDIX: なぜ起動のしかたで並びが変わるか

ログインシェルでは `.zshenv` の後に `/etc/zprofile` の `path_helper` が `/etc/paths` の entry を前へ並べ直し、
その後に `.zprofile` が読まれる。`.zshenv` で前に置いた entry や、export されるガード変数で 1 シェルに 1 回しか
読まれない `home.sessionPath` は、入れ子の `zsh -l` では `path_helper` に後ろへ回されたままになる。

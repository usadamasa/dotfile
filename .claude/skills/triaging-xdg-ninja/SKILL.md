---
name: triaging-xdg-ninja
description: xdg-ninja で $HOME 直下の dotfile を点検し、XDG Base Directory へ移せるものを issue にするときに使う。
---

# triaging-xdg-ninja

xdg-ninja の指摘を「このリポジトリで直せるもの」と「直せないもの」に分け、直せるものを
`usadamasa/dotfile` の issue にする。

## 手順

### 1. 実行する

リポジトリ直下を cwd にして打つ。`command not found` になったら APPENDIX「xdg-ninja が見つからない」へ。

```bash
mkdir -p ./tmp
xdg-ninja --skip-ok --skip-unsupported > ./tmp/xdg-ninja.txt 2>&1
```

- `--skip-ok` で問題の無い項目、`--skip-unsupported` で XDG に対応していないツールを省く
- exit code は指摘の件数になる。0 以外でも失敗ではない
- 出力は ANSI エスケープを含む。Read で読めば `[<tool>]: <path>` の行ごとに指摘を拾える

### 2. 指摘を分類する

指摘ごとに、`.zshenv` と `config/` 配下 (`npmrc` など) の設定を `rg -n` で引き、次の表で分ける。

| 分類 | 見分け方 | 扱い |
| ---- | ---- | ---- |
| 未設定 | xdg-ninja が示す環境変数や設定が `.zshenv` や `config/` に無い | 移す issue を立てる |
| 設定済みで残る (古い) | 設定はあり、`ls -la` で見た $HOME 側の更新日時が古い | 残骸の片付けの issue を立てる。移行先に同じ中身があるかも書く |
| 設定済みで残る (新しい) | 設定はあり、$HOME 側に最近の更新がある | `.zshenv` を読まない経路 (launchd、GUI アプリ、zsh 以外のシェル) が作り直している。原因の調査を issue にする |
| macOS で移せない | `~/.trash`、`$XDG_RUNTIME_DIR` の未設定 | issue にしない。報告に理由を 1 行書く |
| 管轄外 | `~/.claude` | このリポジトリでは扱わない。claude-config が symlink と sandbox のパスを持つ (filing-issues skill) |
| zsh の起点 | `~/.zshenv` | 移さない。`ZDOTDIR` を決めるファイルで、置き換え先の `/etc/zshenv` は sudo が要る |

`$HOME` 側の設定ファイル (`~/.zprofile` など) を読むときは、guard がホーム直下の Read を止めることがある。
止められたら中身は未確認と issue に書き、`ls -la` で分かる種別・サイズ・日付だけを使う。

### 3. 既存 issue と突き合わせる

```bash
gh issue list --repo usadamasa/dotfile --label xdg --state all --limit 100
```

open の issue と同じパスは起票せず、新しく分かったことだけを既存 issue へ comment する。closed の issue と同じパスなら、再発として新しく立て、旧 issue を関連に書く。
xdg-ninja の指摘をまとめる親 issue は #7。

### 4. 起票する

1 パス (またはツール) につき 1 issue。同じ時刻に作り直されたものは原因が同じと見て 1 つにまとめる。本文を `./tmp/issue-<tool>.md` に Write で書き、`--body-file` で渡す。

```bash
gh issue create --repo usadamasa/dotfile --label xdg --assignee usadamasa --title '~/.parallel を XDG 対応させる' --body-file ./tmp/issue-parallel.md
```

タイトルにバッククォートを入れない。`gh` が sandbox の外へ出る照合から外れ、guard が止める。

本文の節は次の順に置く。

1. 背景: xdg-ninja の該当出力 (コードブロック) と、#7 の一環であること
2. 現状: `.zshenv` や `config/` の該当行 (`path:line`)、`ls -la` で見た $HOME 側の中身と日付
3. やること
4. 完了条件: チェックボックス。手順 1 の xdg-ninja の出力から指摘が消えることを含める
5. 未決事項: 移し先 (`$XDG_DATA_HOME` か `$XDG_CACHE_HOME` か)、既存データの扱いなど
6. 関連: #7 と、関係する既存 issue

## APPENDIX: xdg-ninja が見つからない

xdg-ninja は Homebrew ではなく、このリポジトリの devShell (`flake.nix`) から入る。
`command not found` は devShell が Bash へ未反映の状態で、resolving-path skill に従う。

## APPENDIX: なぜこの分類になるか

xdg-ninja はパスの存在だけを見る。環境変数を設定した後も、移す前のディレクトリが残っていれば、
設定済みのツールでも同じ指摘が出る。設定の追加が要るのか、片付けか調査が要るのかは、
設定の有無と $HOME 側の更新日時を合わせて見ないと分からない。

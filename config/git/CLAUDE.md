# CLAUDE.md

<!-- このファイルは上位のCLAUDE.mdを継承しています -->
<!-- 上位CLAUDE.md: ../../CLAUDE.md -->

## このディレクトリについて

Git のグローバル設定ファイル群を管理するディレクトリ。`~/.config/git/` にシンプリンクされ、XDG Base Directory 準拠の配置で動作する。

## 設定の仕組み

### ユーザー自動切替

`config` 内の `includeIf` ディレクティブにより、`gitdir` ベースでユーザー情報を自動切替する:

- **デフォルト**: `gitconfig.local` (環境固有アカウント)
- **`~/src/github.com/usadamasa/` 配下**: `gitconfig.private` (個人アカウント)

### カスタムエイリアス

- `git bare-clone <url>` - bare clone を `<ghq.root>/<host>/<owner>/<repo>/.git` に配置｡refspec 設定 & fetch & HEAD 自動設定まで一括実行
- `git mc` - メインブランチに切替 + pull + `gh poi` でマージ済みブランチ削除

### pager: issue / PR 参照のリンク化

`[pager]` の `log` / `show` は `git-osc8-refs` を挟み、出力中の `#123` を OSC 8
ハイパーリンクへ変換する (リンク先は origin から組み立てた
`https://github.com/<owner>/<repo>/issues/<番号>`)。Ghostty 上で cmd + クリック、
または less の `^O^N` / `^O^O` で開ける。

- Ghostty 1.3.1 の `link` (任意の正規表現をクリック可能にする設定) は未実装なので、
  端末側ではなく出力側で OSC 8 を吐く方式を採っている
- `less` には `-R` が必須。付けないと OSC 8 が端末まで届かない
- リンク先が決まらないとき (リポジトリ外・origin なし・GitHub 以外のホスト) は
  入力をそのまま素通しする。pager は常に挟まるためエラー終了させてはいけない
- GitHub Enterprise などは `GIT_OSC8_REFS_BASE` にリポジトリの Web URL を設定する
- `owner/repo#99` (別リポジトリ参照) と `#42abcd` (16 進カラー) は変換しない。
  ただし `#420` のような 3 桁の 16 進カラーは番号と区別できないため変換される

なお、その上にある `[page]` セクションは `[pager]` の綴り間違いで git からは
無視されている。挙動を変えないためそのまま残してある。

### git-wt (worktree) 設定

`[wt]` セクションで worktree 作成時の挙動を制御:

- ignored/untracked/modified ファイルをコピー
- `.envrc` があれば `direnv allow` を自動実行
- worktree の配置先: `../worktrees/{gitroot}`

## その他の注意事項

- `gitconfig.private` にはメールアドレス等の個人情報が含まれるため、コミット時に内容を確認すること
- `config` 内のパスは `~/.config/git/` を基準にしているため、シンプリンク先を意識すること
- `ignore` の変更は全リポジトリに影響する

# CLAUDE.md

<!-- このファイルは上位のCLAUDE.mdを継承しています -->
<!-- 上位CLAUDE.md: ../../CLAUDE.md -->

## このディレクトリについて

Git のグローバル設定ファイル群を管理するディレクトリ。home-manager (`home/files.nix`) が `~/.config/git/` に symlink を張り、XDG Base Directory 準拠の配置で動作する。

## 設定の仕組み

### ユーザー自動切替

`config` の `user` が既定。端末ローカルの `gitconfig.local` が `includeIf` で特定ディレクトリ配下だけ
別の identity に差し替える。切替の条件と差し替える内容はどちらも端末ローカルに置き、コミットしない。

条件から漏れたディレクトリでは既定が使われる。公開リポジトリへ意図しないアドレスが載るより、
その逆のほうが被害が小さいという判断でこの向きにしてある。

### カスタムエイリアス

- `git mc` - メインブランチに切替 + pull + `gh poi` でマージ済みブランチ削除

### pager

`log` / `show` / `diff` は diff-highlight を挟み、変更行の中で変わった部分を強調する。
diff-highlight は home-manager の git (`home/packages.nix`) の contrib に同梱されていて PATH には載らないため、
`${XDG_STATE_HOME:-$HOME/.local/state}/nix/profile/share/git/contrib/diff-highlight/` のパスで呼ぶ。
pager は git が `sh -c` で実行するので変数が効く。`http.sslCAInfo` はパス型で `~` しか展開されないので、そちらは直書き。

### TLS 証明書検証

`http.sslCAInfo` で home-manager の cacert (`home/packages.nix`) の
`~/.local/state/nix/profile/etc/ssl/certs/ca-bundle.crt` を指す。
git は macOS の libcurl を使い、既定では `/etc/ssl/cert.pem` を読む。
このファイルは OS の更新まで直らず、秘密鍵が漏洩した中間 CA の親ルートが残ることがある。
nixpkgs の cacert は Mozilla の CA bundle に追従して先に直り、flake.lock の更新 (Dependabot 週次) で進む。
`nix-daemon.sh` が `NIX_SSL_CERT_FILE` に選ぶのも同じファイルなので、git・nix・nixpkgs の curl / wget が同じ bundle を読む。
ファイルが無いと https の git 操作がすべて失敗するので、`sslVerify = false` で回避しない。

### git-wt (worktree) 設定

`[wt]` セクションで worktree 作成時の挙動を制御:

- ignored/untracked/modified ファイルをコピー
- `.envrc` があれば `direnv allow` を自動実行
- worktree の配置先: `../worktrees/{gitroot}`

## その他の注意事項

- `config` 内のパスは `~/.config/git/` を基準にしているため、シンプリンク先を意識すること
- `ignore` の変更は全リポジトリに影響する

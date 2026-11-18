# Brewfile から移した CLI ツール (辞書順)。
# PATH は config/zsh/zprofile が nix の profile を brew と /usr/bin より前に置くのでこちらが使われるが、
# brew 版が残ると更新だけ続くので、ここへ移したら Brewfile から消して brew uninstall するまでが 1 単位
{ pkgs, lib, username, ... }:
{
  home.packages = with pkgs; [
    _1password-cli
    # この端末では使っていないが、別の端末で使う (home/ の設定は全端末で共有する)
    aqua
    bashInteractive
    # CLI ではなく Mozilla の CA bundle (etc/ssl/certs/ca-bundle.crt)。config/git/config の http.sslCAInfo が指し、
    # nix-daemon.sh も NIX_PROFILES の後ろ (user profile) を優先して NIX_SSL_CERT_FILE に選ぶので、
    # git・nix・nixpkgs の curl / wget が同じ bundle を読む
    cacert
    # GNU 版は g 接頭辞付き (gdate など) だけ置く。coreutils は ls や cp を接頭辞なしで置き、macOS 版を隠す
    coreutils-prefixed
    curl
    ffmpeg
    gh
    ghq
    gibo
    git
    git-filter-repo
    git-wt
    # plugin (agents-daemon、orm-discovery、acm-discovery) の SessionStart hook が direnv の外で go build する。
    # orm-discovery の go.mod が 1.27.3 を要り、1.26 系の `go` だと GOTOOLCHAIN=auto で toolchain を取りに行くので版付きの attr を使う。
    #
    # 2026-11-10 の security release (cgo のビルド時コード実行ほか 12 件、GO-2026-6859 ほか) の修正版 1.27.4 が
    # nixpkgs では staging 止まりで、nixos-unstable の go_1_27 は 1.27.3 のまま。
    # NixOS/nixpkgs#586269 (staging へ 2026-11-11 に merge 済み) が version と hash だけの差分と確認したうえで、
    # 同じ src (go.dev の go1.27.4.src.tar.gz、sha256 は同 PR の hash と一致確認済み) を当てて追いつく。
    # 進み具合: https://nixpk.gs/pr-tracker.html?pr=586269
    # nixos-unstable の go_1_27 が 1.27.4 以上になったら、この overrideAttrs を外して `go_1_27` に戻す
    (go_1_27.overrideAttrs (finalAttrs: _: {
      version = "1.27.4";
      src = fetchurl {
        url = "https://go.dev/dl/go${finalAttrs.version}.src.tar.gz";
        sha256 = "73cfb8571aec0c01177687db87163d46aa20e9779672772891aa17654d9a6099";
      };
    }))
    # masaru_uchida の端末で cask の gcloud-cli から移した。store が読み取り専用で `gcloud components install` は効かないので、
    # components はここへ足す (bq、gsutil、gcloud-crc32c は本体に入る)。zsh の補完は profile の site-functions から読まれる
    (google-cloud-sdk.withExtraComponents (
      with google-cloud-sdk.components;
      [
        alpha
        beta
        cloud-run-proxy
        gke-gcloud-auth-plugin
        pubsub-emulator
      ]
    ))
    jq
    # kubectl のプラグインは krew を使わず nixpkgs のパッケージで入れる (krew の ctx は kubectx で足りる)
    kube-capacity
    kubectl
    kubectx
    kustomize
    ncdu
    # npm と npx も同梱。global install 先は NPM_CONFIG_PREFIX ($XDG_DATA_HOME/npm、home/zsh.nix) で、
    # その bin は config/zsh/zprofile が PATH に載せる。
    # nixpkgs の nodejs が 24.22.1 (2026-10-21 の security release) に追いつくまで公式バイナリで代替する。
    # 追いついたら `nodejs` に戻す (理由と確認先は nodejs-bin.nix)
    (callPackage ./nodejs-bin.nix { })
    # cargo の openssl-sys crate が pkg-config 経由で見つける用。.pc は dev 出力にあり、
    # bin/man だけの既定出力 (outputsToInstall) では入らないので dev を明示する
    openssl.dev
    peco
    # pkgconf の実行ファイル名は pkgconf で pkg-config ではないため、pkg-config という名前を置く
    # こちらの属性を使う。PKG_CONFIG_PATH は home/zsh.nix の home.sessionVariables が通す
    pkg-config
    pre-commit
    python315
    ripgrep
    # agents-config の global hook (shellcheck-on-write.sh) がどのリポジトリでも command -v で探す。
    # devShell だけにあるツール (bats など) と違い、direnv の外でも要る
    shellcheck
    tig
    tree
    vim
    watch
    wget
    # zsh 本体と ZLE の plugin は programs.zsh (zsh.nix) が入れる。補完は profile の site-functions から読まれる
    zsh-completions
  ]
  ++ lib.optionals (username == "masaru_uchida") [
    postgresql
    rustup
  ];
}

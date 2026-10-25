# Brewfile から移した CLI ツール (辞書順)。
# PATH は config/zsh/zprofile が nix の profile を brew と /usr/bin より前に置くのでこちらが使われるが、
# brew 版が残ると更新だけ続くので、ここへ移したら Brewfile から消して brew uninstall するまでが 1 単位
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # この端末では使っていないが、別の端末で使う (home/ の設定は全端末で共有する)
    aqua
    bashInteractive
    # CLI ではなく Mozilla の CA bundle (etc/ssl/certs/ca-bundle.crt)。config/git/config の http.sslCAInfo が指し、
    # nix-daemon.sh も NIX_PROFILES の後ろ (user profile) を優先して NIX_SSL_CERT_FILE に選ぶので、
    # git・nix・nixpkgs の curl / wget が同じ bundle を読む
    cacert
    curl
    ffmpeg
    gh
    ghq
    gibo
    git
    git-filter-repo
    git-wt
    # plugin (agents-daemon、orm-discovery、acm-discovery) の SessionStart hook が direnv の外で go build する。
    # orm-discovery の go.mod が 1.27.3 を要り、1.26 系の `go` だと GOTOOLCHAIN=auto で toolchain を取りに行くので版付きの attr を使う
    go_1_27
    jq
    # nixpkgs の krew は bin/krew だけを持ち、kubectl のプラグイン探索に要る kubectl-krew の名前が無いので足す。
    # krew 公式の `krew install krew` は自己更新する kubectl-krew を ~/.krew/bin (PATH で nix より前) に置くので使わない
    (symlinkJoin {
      name = "krew";
      paths = [ krew ];
      postBuild = "ln -s krew $out/bin/kubectl-krew";
    })
    kubectl
    kubectx
    kustomize
    ncdu
    # npm と npx も同梱。global install 先は config/npm/npmrc の prefix ($XDG_DATA_HOME/npm) で、
    # その bin は config/zsh/zprofile が PATH に載せる。
    # nixpkgs の nodejs が 24.22.1 (2026-10-21 の security release) に追いつくまで公式バイナリで代替する。
    # 追いついたら `nodejs` に戻す (理由と確認先は nodejs-bin.nix)
    (callPackage ./nodejs-bin.nix { })
    peco
    pipx
    ripgrep
    # claude-config の global hook (shellcheck-on-write.sh) がどのリポジトリでも command -v で探す。
    # devShell だけにあるツール (bats など) と違い、direnv の外でも要る
    shellcheck
    tig
    tree
    vim
    watch
    wget
    # zsh 本体と ZLE の plugin は programs.zsh (zsh.nix) が入れる。補完は profile の site-functions から読まれる
    zsh-completions
  ];
}

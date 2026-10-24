# Brewfile から移した CLI ツール (辞書順)。
# PATH は config/zsh/.zprofile が nix の profile を brew と /usr/bin より前に置くのでこちらが使われるが、
# brew 版が残ると更新だけ続くので、ここへ移したら Brewfile から消して brew uninstall するまでが 1 単位
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bashInteractive
    gh
    ghq
    git-filter-repo
    jq
    # npm と npx も同梱。global install 先は config/npm/npmrc の prefix ($XDG_DATA_HOME/npm) で、
    # その bin は config/zsh/.zprofile が PATH に載せる。
    # nixpkgs の nodejs が 24.22.1 (2026-10-21 の security release) に追いつくまで公式バイナリで代替する。
    # 追いついたら `nodejs` に戻す (理由と確認先は nodejs-bin.nix)
    (callPackage ./nodejs-bin.nix { })
    peco
    pipx
    # claude-config の global hook (shellcheck-on-write.sh) がどのリポジトリでも command -v で探す。
    # devShell だけにあるツール (bats など) と違い、direnv の外でも要る
    shellcheck
    tig
    tree
    watch
    wget
  ];
}

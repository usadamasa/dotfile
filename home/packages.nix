# Brewfile から移した CLI ツール (辞書順)。
# 対話シェルの PATH は /opt/homebrew/bin が nix の profile より前なので、
# ここへ移したら Brewfile から消して brew uninstall するまでが 1 単位
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # npm と npx も同梱。global install 先は config/npm/npmrc の prefix ($XDG_DATA_HOME/npm) で、
    # その bin は config/zsh/.zprofile が PATH に載せる。
    # nixpkgs の nodejs が 24.22.1 (2026-10-21 の security release) に追いつくまで公式バイナリで代替する。
    # 追いついたら `nodejs` に戻す (理由と確認先は nodejs-bin.nix)
    (callPackage ./nodejs-bin.nix { })
  ];
}

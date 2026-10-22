# Brewfile から移した CLI ツール (辞書順)。
# 対話シェルの PATH は /opt/homebrew/bin が nix の profile より前なので、
# ここへ移したら Brewfile から消して brew uninstall するまでが 1 単位
{ pkgs, ... }:
{
  home.packages = with pkgs; [
  ];
}

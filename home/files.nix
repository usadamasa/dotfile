# $HOME と ~/.config 配下へ張る設定ファイル。
# mkOutOfStoreSymlink でリポジトリの作業ツリーを直接指すので、編集が即反映され、bats テストの前提も変わらない。
# 世代を戻してもリンクが戻るだけで、リポジトリ側の内容は戻らない
{ config, ... }:
let
  # flake は pure 評価で ./. が store のコピーになるため、ghq の配置を文字列で書く
  dotfileDir = "${config.home.homeDirectory}/src/github.com/usadamasa/dotfile";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfileDir}/${path}";
in
{
  home.file.".zshenv".source = link ".zshenv";

  xdg.configFile = {
    # ~/.config/direnv は home-manager が lib/ を書くので、ディレクトリごとではなくファイル単位で張る
    "direnv/direnv.toml".source = link "config/direnv/direnv.toml";
    "git".source = link "config/git";
    "npm".source = link "config/npm";
    "vim".source = link "config/vim";
    "zsh".source = link "config/zsh";
  };
}

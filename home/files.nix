# ~/.config 配下へ張る設定ファイル。
# mkOutOfStoreSymlink でリポジトリの作業ツリーを直接指すので、編集が即反映され、bats テストの前提も変わらない。
# 世代を戻してもリンクが戻るだけで、リポジトリ側の内容は戻らない
{ config, dotfileDir, ... }:
let
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfileDir}/${path}";
in
{
  xdg.configFile = {
    # ~/.config/direnv は home-manager が lib/ を書くので、ディレクトリごとではなくファイル単位で張る
    "direnv/direnv.toml".source = link "config/direnv/direnv.toml";
    "git".source = link "config/git";
    "vim".source = link "config/vim";
  };
}

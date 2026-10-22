# ~/.config 配下へ張る設定ファイル。Taskfile の _setup-config の ln -sfn を 1 行ずつここへ移す。
# mkOutOfStoreSymlink でリポジトリの作業ツリーを直接指すので、編集が即反映され、bats テストの前提も変わらない。
# 世代を戻してもリンクが戻るだけで、リポジトリ側の内容は戻らない
{ config, ... }:
let
  # flake は pure 評価で ./. が store のコピーになるため、ghq の配置を文字列で書く
  dotfileDir = "${config.home.homeDirectory}/src/github.com/usadamasa/dotfile";
  link = path: config.lib.file.mkOutOfStoreSymlink "${dotfileDir}/${path}";
in
{
  xdg.configFile = {
    "npm".source = link "config/npm";
  };
}

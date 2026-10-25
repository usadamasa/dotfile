# gh extension を nixpkgs のパッケージで置く。
# programs.gh は ~/.config/gh/config.yml を生成して既存の設定と衝突し、extensions も gh/extensions を丸ごと持つので使わない。
# extension ごとにディレクトリを張り、gh extension install で入れたもの (gh-aw など) と並べる
{ pkgs, ... }:
{
  xdg.dataFile = {
    # config/git/git-mc が gh poi を呼ぶ
    "gh/extensions/gh-poi".source = "${pkgs.gh-poi}/bin";
  };
}

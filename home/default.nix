# home-manager (standalone) の入口。Taskfile の処理を 1 つずつここへ移す (issue #105)。
# username は flake.nix の users から extraSpecialArgs で渡る
{ username, ... }:
{
  imports = [
    ./files.nix
    ./packages.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  # 初回導入時の home-manager の版。上げると既存環境の互換挙動が変わるので、理由なく変えない
  home.stateVersion = "26.05";

  xdg.enable = true;
  # use-xdg-base-directories は system 側 (/etc/nix/nix.custom.conf) に置いていて home-manager からは見えない。
  # これが無いと home.profileDirectory が ~/.nix-profile (この端末に無い) になる
  nix.assumeXdg = true;

  # home-manager CLI を profile に入れる (generations / --rollback 用)。適用自体は home/switch.sh
  programs.home-manager.enable = true;
  news.display = "silent";
}

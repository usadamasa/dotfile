# home/ の設定を homeDirectory だけ差し替えてビルドする (tests/zsh-home-manager.bats 用)。
# 生成物は絶対パスを埋め込むので、本物の HOME 向けの activationPackage では偽の HOME で起動できない
{ flakeRef, home, username ? "usadamasa" }:
let
  flake = builtins.getFlake flakeRef;
  pkgs = flake.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
in
(flake.inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  modules = [
    "${flake}/home"
    {
      home.homeDirectory = pkgs.lib.mkForce home;
      # xdg.*Home の既定は環境変数の XDG_*_HOME を拾い、--impure ではビルドした人の HOME になる
      xdg.cacheHome = "${home}/.cache";
      xdg.configHome = "${home}/.config";
      xdg.dataHome = "${home}/.local/share";
      xdg.stateHome = "${home}/.local/state";
      xdg.binHome = "${home}/.local/bin";
    }
  ];
  extraSpecialArgs = { inherit username; };
}).activationPackage

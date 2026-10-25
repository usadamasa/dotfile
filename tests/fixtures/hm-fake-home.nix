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
    { home.homeDirectory = pkgs.lib.mkForce home; }
  ];
  extraSpecialArgs = { inherit username; };
}).activationPackage

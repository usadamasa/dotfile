{
  description = "dotfile の開発ツール";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      # ローカル (Apple Silicon) と、クラウド環境や CI 向けの linux
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
      forEach = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forEach (pkgs: {
        # mkShellNoCC: シェルスクリプトだけなので clang / Apple SDK を持ち込まない。
        # stdenv の coreutils / gnused / gnugrep / findutils は残り、PATH の先頭で GNU 版が macOS 版を隠す。
        default = pkgs.mkShellNoCC {
          # 辞書順。日常的に使うツールは Brewfile に残し、ここにはこのリポジトリの開発・テストに要るものだけ置く
          packages = with pkgs; [
            bats
            editorconfig-checker
            go-task
            shellcheck
            yamllint
          ];
        };
      });
    };
}

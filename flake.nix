{
  description = "dotfile の開発ツールとホーム環境 (home-manager)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      # nixpkgs が nixos-unstable なので home-manager も master を対にする (release-XX.YY は stable 用)
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      # ローカル (Apple Silicon) と、クラウド環境や CI 向けの linux
      systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-linux" ];
      forEach = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # 端末ごとのユーザー名。home-manager CLI は `switch --flake .` で $USER の設定を選ぶ。
      # ホスト名は付けない: macOS の hostname はネットワークで taylor.local / taylor と揺れ、
      # CLI は $USER@<hostname> の候補のうち最後に一致した名前を採るため名前が安定しない
      users = [ "masaru_uchida" "usadamasa" ];
      mkHome = username: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfreePredicate = pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "1password-cli" ];
        };
        modules = [ ./home ];
        extraSpecialArgs = { inherit username; };
      };
    in
    {
      devShells = forEach (pkgs: {
        # mkShellNoCC: シェルスクリプトだけなので clang / Apple SDK を持ち込まない。
        # stdenv の coreutils / gnused / gnugrep / findutils は残り、PATH の先頭で GNU 版が macOS 版を隠す。
        default = pkgs.mkShellNoCC {
          # 辞書順。日常的に使うツールは home-manager (home/packages.nix) に置き、ここにはこのリポジトリの開発・テストに要るものだけ置く
          packages = with pkgs; [
            bats
            editorconfig-checker
            go-task
            jq
            shellcheck
            xdg-ninja
            yamllint
            zsh # tests/zprofile.bats が config/zsh/zprofile を zsh で読む。CI のランナーには入っていない
          ];
        };
      });

      # 適用は home/switch.sh (task hm:switch)
      homeConfigurations = nixpkgs.lib.genAttrs users mkHome;

      # home/switch.sh が使う home-manager CLI。flake.lock で homeConfigurations と同じ版に固定される
      packages = nixpkgs.lib.genAttrs systems (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });
    };
}

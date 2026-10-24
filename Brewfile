# 日常使いの CLI は home-manager (home/packages.nix)、このリポジトリの開発ツールは flake.nix の devShell に置く。
# ここには nixpkgs に無いもののみ残す
brew "aqua"
brew "coreutils"
brew "git-now"
brew "vim"
brew "zsh"
cask "font-cica"
cask "font-hack-nerd-font"

# 以下は Homebrew で管理しない (更新のたびに sudo パスワードを要求されるため)。
# 各アプリ自身のインストーラと自動更新に任せる。
#   - claude (Desktop)    : https://claude.ai/download から .dmg
#   - claude-code         : curl -fsSL https://claude.ai/install.sh | bash
#   - codex               : npm i -g @openai/codex
#   - nix                 : bootstrap.sh (Determinate Nix のインストーラ)
#   - jetbrains-toolbox   : https://www.jetbrains.com/toolbox-app/ から .dmg
#   - visual-studio-code  : https://code.visualstudio.com/ から .zip

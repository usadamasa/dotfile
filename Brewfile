# 日常使いの CLI は home-manager (home/packages.nix)、このリポジトリの開発ツールは flake.nix の devShell に置く。
# ここに残るのは nixpkgs に無いもの、ログインシェル、cask、ほかの設定が /opt/homebrew のパスを指しているもの、
# ほか issue #105 の「Brew に残すもの」(coreutils は nixpkgs 版が ls / cp で macOS 版を隠す)
brew "aqua"
brew "ca-certificates"
brew "coreutils"
brew "curl"
brew "git-now" # nixpkgs に無い
brew "git"
brew "k1low/tap/git-wt"
brew "vim"
brew "zsh"
cask "font-cica"
cask "font-hack-nerd-font"
tap "k1low/tap"

# 以下は Homebrew で管理しない (更新のたびに sudo パスワードを要求されるため)。
# 各アプリ自身のインストーラと自動更新に任せる。
#   - claude (Desktop)    : https://claude.ai/download から .dmg
#   - claude-code         : curl -fsSL https://claude.ai/install.sh | bash
#   - codex               : npm i -g @openai/codex
#   - nix                 : bootstrap.sh (Determinate Nix のインストーラ)
#   - jetbrains-toolbox   : https://www.jetbrains.com/toolbox-app/ から .dmg
#   - visual-studio-code  : https://code.visualstudio.com/ から .zip

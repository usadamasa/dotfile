# direnv 本体と nix-direnv。nix-direnv は ~/.config/direnv/lib/hm-nix-direnv.sh として置かれ、
# direnv が lib/*.sh を自動で読むので手書きの direnvrc は要らない。
# direnv.toml は programs.direnv.config で生成するとコメント (whitelist の理由) が落ちるため、files.nix で symlink する。
# zsh の hook は enableZshIntegration (既定で有効) が programs.zsh の .zshrc に書く
{
  programs.direnv.enable = true;
}

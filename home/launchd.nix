# Dock や Spotlight から起動した GUI アプリ (Claude Desktop など) は .zshenv を読まず、launchd の環境だけを引き継ぐ。
# アプリとその子プロセスが $HOME 直下に dotfile を作らないよう、ログイン時に渡す
{ config, lib, ... }:
let
  variables = lib.getAttrs [
    "CODEX_HOME"
    "GOPATH"
    "NPM_CONFIG_CACHE"
    "NPM_CONFIG_INIT_MODULE"
    "NPM_CONFIG_PREFIX"
    "PLATFORMIO_CORE_DIR"
  ] config.home.sessionVariables;
  # launchctl setenv は 1 回に 1 組しか受け付けない
  script = lib.concatLines (
    [ "set -eu" ]
    ++ lib.mapAttrsToList (name: value: "/bin/launchctl setenv ${name} ${lib.escapeShellArg value}") variables
  );
in
{
  launchd.agents.session-variables = {
    enable = true;
    config = {
      ProgramArguments = [ "/bin/sh" "-c" script ];
      RunAtLoad = true;
    };
  };
}

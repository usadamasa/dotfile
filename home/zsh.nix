# zsh の設定 (~/.zshenv と ~/.config/zsh/.{zshenv,zprofile,zshrc}) を programs.zsh で生成する。
# option の無い中身は config/zsh/ の断片を readFile で取り込むので、断片を変えたら task hm:switch が要る
{ config, lib, dotfileDir, ... }:
let
  inherit (config) xdg;
in
{
  # ZDOTDIR は stateVersion 26.05 と xdg.enable の既定で ~/.config/zsh になる
  programs.zsh = {
    enable = true;

    # home.sessionVariables はガード変数で 1 シェル 1 回しか読まれないので、毎回評価が要るものだけここに置く
    envExtra = ''
      # Terminal.app の Resume 用セッション保存を止める。
      # /etc/zshrc_Apple_Terminal は保存先を ''${ZDOTDIR}/.zsh_sessions に固定しており、移せない
      # https://github.com/usadamasa/dotfile/issues/3
      SHELL_SESSIONS_DISABLE=1

      # The installer hooks only /etc/zshrc, so non-interactive shells (zsh -c, the
      # shell nix-direnv runs under) would miss nix and nix-direnv would silently fall
      # back to its bundled upstream nix. The script guards itself against double
      # sourcing, so /etc/zshrc becomes a no-op afterwards.
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';

    profileExtra = builtins.readFile ../config/zsh/zprofile;

    oh-my-zsh = {
      enable = true;
      theme = "amuse";
      # direnv の hook は programs.direnv が張るので、oh-my-zsh の direnv plugin は使わない。
      # gcloud plugin は brew や公式 installer の置き場しか探さず、nix の google-cloud-sdk (packages.nix) を見つけない
      plugins = [ ];
      extraConfig = ''
        # oh-my-zsh の compinit は ZSH_COMPDUMP が無いと ZDOTDIR にダンプを書く
        ZSH_COMPDUMP="${xdg.cacheHome}/zsh/zcompdump-$ZSH_VERSION"
        HIST_STAMPS="yyyy-mm-dd"
      '';
    };

    autosuggestion.enable = true;
    syntaxHighlighting = {
      enable = true;
      # main は home-manager が足す
      highlighters = [ "brackets" "pattern" "cursor" ];
    };

    # home-manager は全 option を setopt / NO_ で書き、oh-my-zsh の設定より後に入るので、既定に任せず明示する
    history = {
      path = "${xdg.stateHome}/zsh/history";
      size = 10000000;
      save = 10000000;
      append = true;
      expireDuplicatesFirst = true;
      extended = true;
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      saveNoDups = true;
      share = true;
    };

    initContent = lib.concatStringsSep "\n" [
      (builtins.readFile ../config/zsh/zshrc)
      (builtins.readFile ../config/zsh/funcs/peco-select-history.sh)
      (builtins.readFile ../config/zsh/funcs/peco-src.sh)
      (builtins.readFile ../config/zsh/funcs/task-completion.zsh)
      # 端末ごとの設定。gitignore 済みのファイルを取り込まず、作業ツリーから読む
      ''[ -s "${dotfileDir}/config/zsh/.zshrc.local" ] && . "${dotfileDir}/config/zsh/.zshrc.local"''
    ];
  };

  home.sessionPath = [ "$HOME/.local/bin" ];

  home.sessionVariables = {
    VIMINIT = ''let \$MYVIMRC=\"${xdg.configHome}/vim/vimrc\" | source \$MYVIMRC'';
    VIMDOTDIR = "${xdg.configHome}/vim";
    LESSHISTFILE = "${xdg.stateHome}/less/history";
    # sqlite3 は履歴ファイルの親ディレクトリを作らない (xdg.stateHome は xdg.enable が作る)
    SQLITE_HISTORY = "${xdg.stateHome}/sqlite_history";
    NPM_CONFIG_USERCONFIG = "${xdg.configHome}/npm/npmrc";
    GOPATH = "${xdg.dataHome}/go";
    GRADLE_USER_HOME = "${xdg.dataHome}/gradle";
    SDKMAN_DIR = "${xdg.dataHome}/sdkman";
    PIPX_HOME = "${xdg.dataHome}/pipx";
    CARGO_HOME = "${xdg.dataHome}/cargo";
  };

  home.activation.createToolDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p ${
      lib.escapeShellArgs [
        "${xdg.stateHome}/less"
        "${xdg.dataHome}/go"
        "${xdg.dataHome}/gradle"
        "${xdg.dataHome}/pipx"
      ]
    }
  '';
}

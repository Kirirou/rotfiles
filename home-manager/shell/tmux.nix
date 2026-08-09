{ pkgs, ... }: {
  programs.zellij = {
    enable = true;
    enableBashIntegration = false;
    enableFishIntegration = false;
    settings = {
      theme = "gruvbox-dark";
      on_force_close = "detach";
      simplified_ui = false;
      default_shell = "fish";
      show_startup_tips = false;
      show_resease_notes = false;
      pane_frames = false;
      default_layout = "default";
      copy_command = "wl-copy";
      ui = {
        pane_frames = {
          hide_session_name = false;
          rounded_corners = true;
        };
      };
    };
  };
  xdg.configFile."zellij/v2h.swap.kdl".source = ./v2h.swap.kdl;

  systemd.user.services.zellij = {
    Unit = {
      Description = "Zellij session";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.zellij}/bin/zellij attach --create-background main";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.fish.interactiveShellInit = ''
    if test -z "$ZELLIJ"
      exec zellij attach --create main
    end
  '';

  programs.tmux = {
    enable = true;
    prefix = "C-b";
    terminal = "tmux-256color";
    mouse = true;
    keyMode = "vi";
    escapeTime = 0; # no delay for esc key press
    baseIndex = 1; # index panes and windows from 1
    customPaneNavigationAndResize = true; # use vim keys to navigate panes
    extraConfig = ''
      # Saner splitting.
      bind v split-window -h
      bind s split-window -v

      # 16 million colors please
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'

      # Activity
      setw -g monitor-activity off
      set -g visual-activity off

      # Automatically set window title
      setw -g automatic-rename on
      set -g set-titles on

      # Cleaner status bar
      set -g status-style bg=default
      # set -g status-position top

      set -g status-left ""
      set -g status-right ""

      set -g pane-border-style bg=default,fg=colour8
      set -g pane-active-border-style bg=default,fg=colour7

      set -g message-style bg=colour8,fg=colour0

      setw -g window-status-format "#[fg=colour7,nobold,nounderscore,noitalics] #[fg=colour7] #W #[fg=colour0,nobold,nounderscore,noitalics]"
      setw -g window-status-style bg=default,fg=colour7

      setw -g window-status-current-style bg=default,fg=colour7
      setw -g window-status-current-format "#[fg=colour0,nobold,nounderscore,noitalics] #[fg=colour4] #W #[fg=colour0,nobold,nounderscore,noitalics]"

      setw -g window-status-activity-style fg=colour8
    '';
  };
}

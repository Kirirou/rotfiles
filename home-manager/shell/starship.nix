{lib, ...}: {
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    settings = {
      add_newline = true;
      line_break = {
        disabled = true;
      };
      time = {
        disabled = false;
        format = "[$time]($style) ";
        style = "green";
        time_format = "「%H:%M:%S」";
      };
      format = lib.concatStringsSep "" [
        "$time"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_state"
        "$git_status"
        "$nix_shell"
        "$cmd_duration"
        "$python"
        "$character"
      ];
      character = {
        error_symbol = "[>](red)";
        success_symbol = "[>](purple)";
        vimcmd_symbol = "[<](green)";
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };
      directory = {
        style = "blue";

      };
      git_branch = {
        format = "[$branch]($style)";
        style = "yellow";
      };
      git_state = {
        format = "\([$state( $progress_current/$progress_total)]($style)\) ";
        style = "bright-black";
      };
      git_status = {
        conflicted = "​";
        deleted = "​";
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style) ";
        modified = "​";
        renamed = "​";
        staged = "​";
        stashed = "≡";
        style = "cyan";
        untracked = "​";
      };
      nix_shell = {
        format = "[$symbol]($style)";
        symbol = "❄️ ";
        style = "blue";
      };
      python = {
        format = "[$virtualenv]($style) ";
        style = "bright-black";
      };
    };
  };

  # some sort of race condition with kitty and starship
  # https://github.com/kovidgoyal/kitty/issues/4476#issuecomment-1013617251
  programs.kitty.shellIntegration.enableBashIntegration = false;

  custom.persist = {
    home.cache = [
      ".cache/starship"
    ];
  };
}

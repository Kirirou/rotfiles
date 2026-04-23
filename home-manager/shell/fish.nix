{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.custom.shell;
in {
  programs = {
    fish = {
      enable = true;
      functions = {
        yy = ''
        	set tmp (mktemp -t "yazi-cwd.XXXXXX")
        	yazi $argv --cwd-file="$tmp"
        	if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        		cd -- "$cwd"
        	end
        	rm -f -- "$tmp"
        '';
        fish_user_key_bindings = ''
          fish_default_key_bindings -M insert

        '';
      };
      shellAliases = {
        ehistory = "hx ${config.xdg.dataHome}/fish/fish_history";
      };
      shellInit =
        ''
          # shut up welcome message
          set fish_greeting

          # ADD password prompt for gnupg
          set GPG_TTY $(tty)
          export GPG_TTY

          # set options for plugins
          set sponge_regex_patterns 'password|passwd'
          set sponge_filter_failed true
        ''
        # wallust colorscheme
        + lib.optionalString config.custom.wallust.enable ''
          set wallust_colors "${config.xdg.cacheHome}/wallust/sequences"
          if test -e "$wallust_colors"
              command cat "$wallust_colors"
          end
        '';
    };
  };

  # fish plugins, home-manager's programs.fish.plugins has a weird format
  home.packages = with pkgs.fishPlugins; [
    # used as starship's transient prompt does not handle empty commands
    # transient-fish
    # do not add failed commands to history
    sponge
  ];

  programs.man.generateCaches = false;

  # set as default interactive shell
  programs.kitty.settings.shell = lib.mkForce (lib.getExe pkgs.fish);

  custom.persist = {
    home.directories = [
      ".local/share/fish"
    ];
  };
}

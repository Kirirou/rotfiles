{
  pkgs,
  config,
  lib,
  ...
}:
let
  catppuccinDefault = "Blue";
  catppuccinAccents = {
    Blue = "#89b4fa";
    Flamingo = "#f2cdcd";
    Green = "#a6e3a1";
    Lavender = "#b4befe";
    Maroon = "#eba0ac";
    Mauve = "#cba6f7";
    Peach = "#fab387";
    Pink = "#f5c2e7";
    Red = "#f38ba8";
    # Rosewater = "#f5e0dc";
    Sapphire = "#74c7ec";
    Sky = "#89dceb";
    Teal = "#94e2d5";
    Yellow = "#f9e2af";
  };
in
{
  home = {
    pointerCursor = {
      enable = true;
      package = pkgs.simp1e-cursors;
      name = "Simp1e-Gruvbox-Dark";
      size = 28;
      gtk.enable = true;
      x11.enable = true;
    };

    sessionVariables = {
      XCURSOR_SIZE = config.home.pointerCursor.size;
      ADW_DEBUG_COLOR_SCHEME = "prefer-dark";
    };
  };

  dconf.settings = {
    # disable dconf first use warning
    "ca/desrt/dconf-editor" = {
      show-warning = false;
    };

    "com/github/wwmm/easyeffects" = {
        use-dark-theme = true;
    };
    
    # set dark theme for gtk 4
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  home.sessionVariables.GTK_THEME = "gruvbox-dark";

  gtk = {
    enable = true;
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk;
    };
    iconTheme = {
      name = "oomox-gruvbox-dark";
      package = pkgs.gruvbox-dark-icons-gtk;      
    };
    font = {
      name = "${config.custom.fonts.monospace}";
      package = pkgs.nerd-fonts.gohufont;
      size = 6;
    };
    gtk2.configLocation = "${config.xdg.configHome}/gtk-2.0/gtkrc";
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-error-bell = 0;
    };
    gtk4.extraCss = ''
      window, .background {
        background-color: #282828;
        color: #ebdbb2;
      }
      headerbar {
        background-color: #3c3836;
        color: #ebdbb2;
        border-bottom: 1px solid #1d2021;
      }
      .sidebar, list, listview {
        background-color: #282828;
        color: #ebdbb2;
      }
      button {
        background-color: #504945;
        color: #ebdbb2;
      }
      button:hover {
        background-color: #665c54;
      }
      entry, spinbutton {
        background-color: #3c3836;
        color: #ebdbb2;
      }
      scale trough {
        background-color: #504945;
      }
      scale highlight {
        background-color: #b8bb26;
      }
    '';
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-error-bell = 0;
    };
  };

  # write theme accents into nix.json for rust to read
  custom.wallust.nixJson = {
    theme_accents = catppuccinAccents;
  };
}

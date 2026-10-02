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
      text-scaling-factor = 1.15;
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          mkdir -p $out/share/themes/gruvbox-dark/gtk-4.0
          cat > $out/share/themes/gruvbox-dark/gtk-4.0/gtk.css << 'EOF'
@define-color window_bg_color #282828;
@define-color window_fg_color #ebdbb2;
@define-color view_bg_color #1d2021;
@define-color view_fg_color #ebdbb2;
@define-color headerbar_bg_color #3c3836;
@define-color headerbar_fg_color #ebdbb2;
@define-color headerbar_border_color #1d2021;
@define-color sidebar_bg_color #282828;
@define-color sidebar_fg_color #ebdbb2;
@define-color card_bg_color #3c3836;
@define-color card_fg_color #ebdbb2;
@define-color popover_bg_color #3c3836;
@define-color popover_fg_color #ebdbb2;
@define-color dialog_bg_color #282828;
@define-color dialog_fg_color #ebdbb2;
@define-color accent_bg_color #b8bb26;
@define-color accent_fg_color #1d2021;
@define-color accent_color #b8bb26;
@define-color destructive_bg_color #cc241d;
@define-color destructive_fg_color #ebdbb2;
@define-color success_bg_color #98971a;
@define-color warning_bg_color #d79921;
@define-color error_bg_color #cc241d;
EOF
        '';
      });
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
    gtk4.theme = config.gtk.theme;
    gtk4.extraCss = ''
      @define-color theme_bg_color #282828;
      @define-color theme_fg_color #ebdbb2;
      @define-color theme_base_color #1d2021;
      @define-color theme_text_color #ebdbb2;
      @define-color theme_selected_bg_color #b8bb26;
      @define-color theme_selected_fg_color #1d2021;
      @define-color insensitive_bg_color #3c3836;
      @define-color insensitive_fg_color #928374;
      @define-color insensitive_base_color #282828;
      @define-color theme_unfocused_fg_color #a89984;
      @define-color theme_unfocused_text_color #ebdbb2;
      @define-color theme_unfocused_bg_color #282828;
      @define-color theme_unfocused_base_color #1d2021;
      @define-color theme_unfocused_selected_bg_color #98971a;
      @define-color theme_unfocused_selected_fg_color #ebdbb2;
      @define-color borders #504945;
      @define-color unfocused_borders #3c3836;
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

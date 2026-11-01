{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.rofi;
  rofiThemes = "${pkgs.custom.rofi-themes}/files";
  launcherType = 2;
  launcherStyle = 2;
  powermenuType = 4;
  powermenuStyle = 3;
  powermenuDir = "${rofiThemes}/powermenu/type-${toString powermenuType}";
  themeStyles =
    if cfg.theme != null then
      ''@import "${rofiThemes}/colors/${cfg.theme}.rasi"''
    else
      ''
        * {
            background:     {{background}};
            background-alt: {{color0}};
            foreground:     {{foreground}};
            selected:       {{color4}};
            active:         {{color6}};
            urgent:         {{color1}};
        }
      '';

  # Minimal/compact/no-rounded-corners override layer, applied on top of whatever the
  # imported preset theme (rofi-themes type-2/style-2) set - appended after
  # additionalStyles in fixupRofiThemesRasi below so it wins the cascade on any shared
  # selector.
  compactStyles = ''
    window {
      border-radius: 0px;
      border: 0px;
      padding: 0px;
    }
    mainbox {
      padding: 6px;
      spacing: 4px;
    }
    inputbar {
      border-radius: 0px;
      padding: 6px 8px;
      spacing: 6px;
    }
    listview {
      spacing: 2px;
      padding: 2px 0px;
    }
    element {
      border-radius: 0px;
      padding: 4px 8px;
    }
    element-icon {
      size: 20px;
    }
    scrollbar {
      width: 2px;
      border-radius: 0px;
    }
  '';

  # replace the imports with preset theme / wallust
  fixupRofiThemesRasi = rasiPath: additionalStyles: ''
    ${themeStyles}
    ${lib.replaceStrings
      [
        "@import"
        ""
      ]
      [
        "// @import"
        ""
      ]
      (lib.readFile rasiPath)
    }
    window {
      width: ${toString cfg.width}px;
    }
    ${additionalStyles}
    ${compactStyles}
  '';
in
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
  };

  custom.shell.packages = {
    # NOTE: rofi-power-menu only works for powermenuType = 4!
    rofi-power-menu = pkgs.writeShellApplication {
      name = "rofi-power-menu";
      runtimeInputs = with pkgs; [
        rofi
        custom.rofi-themes
      ];
      text = lib.replaceStrings [ "@theme@" ] [
        (builtins.toFile "rofi-power-menu.rasi" (
          (lib.readFile "${powermenuDir}/style-${toString powermenuStyle}.rasi")
          + ''
            * { background-window: black/60%; } // darken background
            window { border-radius: 0px; } // minimal/compact styling, no rounded corners
          ''
        ))
      ] (lib.readFile ./rofi-power-menu.sh);
    };
  };

  xdg.configFile = {
    "rofi/rofi-wifi-menu" = lib.mkIf config.custom.wifi.enable {
      # https://github.com/ericmurphyxyz/rofi-wifi-menu/blob/master/rofi-wifi-menu.sh
      source = ./rofi-wifi-menu.sh;
    };

    "rofi/config.rasi".text = ''
      @theme "${config.xdg.cacheHome}/wallust/rofi.rasi"
    '';
  };

  # add blur for rofi shutdown + force center on monitor
  wayland.windowManager.hyprland.settings = {
    layer_rule = [
      { match.namespace = "rofi"; blur = true; ignore_alpha = 0; }
    ];

    window_rule = [
      { match.class = "Rofi"; float = true; center = true; rounding = 0; }
    ];
  };

  custom.wallust.templates = lib.mkIf config.programs.rofi.enable {
    # default launcher
    "rofi.rasi" = {
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString launcherType}/style-${toString launcherStyle}.rasi" "";
      target = "${config.xdg.cacheHome}/wallust/rofi.rasi";
    };

    # generic single column rofi menu
    "rofi-menu.rasi" = {
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString launcherType}/style-${toString launcherStyle}.rasi" ''
        listview {
          columns: 1;
          lines: 6;
        }
        prompt { enabled: false; }
        textbox-prompt-colon { enabled: false; }
      '';
      target = "${config.xdg.cacheHome}/wallust/rofi-menu.rasi";
    };

    "rofi-screenshot.rasi" = {
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString launcherType}/style-${toString launcherStyle}.rasi" ''
        listview {
          columns: 1;
          lines: 6;
        }
        * { width: 1000; }
        window { height: 625; }
        mainbox {
            children: [listview,message];
        }
        message {
          padding:                     15px;
          border:                      0px solid;
          border-radius:               0px;
          border-color:                @selected;
          background-color:            @background;
          text-color:                  @foreground;
        }
      '';
      target = "${config.xdg.cacheHome}/wallust/rofi-screenshot.rasi";
    };

    "rofi-power-menu-confirm.rasi" = {
      text = fixupRofiThemesRasi "${powermenuDir}/shared/confirm.rasi" "";
      target = "${config.xdg.cacheHome}/wallust/rofi-power-menu-confirm.rasi";
    };
  };
}

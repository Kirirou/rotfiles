{ config, lib, host, isLaptop, pkgs, ... }:
let hyprlandCfg = config.wayland.windowManager.hyprland;
in {
  options.custom = {
    display.touchDevice = {
      enabled = lib.mkEnableOption "Enable Touchscreen device support" // {
        default = false;
      };
      transform = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = ''
          Transform the input of a touchscreen to match the monitor rotation
          This will be done automatically when #3544 lands.
          https://github.com/hyprwm/Hyprland/pull/3544

          normal (no transforms) -> 0
          90 degrees -> 1
          180 degrees -> 2
          270 degrees -> 3
          flipped -> 4
          flipped + 90 degrees -> 5
          flipped + 180 degrees -> 6
          flipped + 270 degrees -> 7
        '';
      };
      devIndex = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = ''
          (Starts from 0) specify which monitor in displays list
          is to be considered touchdevice an input.touchdevice.output by hyprland
          https://wiki.hyprland.org/Configuring/Variables/#touchdevice
        '';
      };
    };
    displays = lib.mkOption {
      type = with lib.types;
        listOf (submodule {
          options = {
            display_name_output = lib.mkOption {
              type = str;
              description = "The name of the display, e.g. eDP-1";
            };
            mode = lib.mkOption {
              type = str;
              description = ''
                resolution and refresh rate
                e.g. 3440x1440@160
              '';
              default = "auto";
            };
            position = lib.mkOption {
              type = str;
              description = ''
                where monitor is located positionally
                e.g. 0x0
                or
                -2560x0
              '';
              default = "0x0";
            };
            addreserved = lib.mkOption {
              type = str;
              description = ''
                TOP, BOTTOM, LEFT, RIGHT
                Example:
                600, 0, 0, 0

                600 pixels from the top reserved area
              '';
              default = "0, 0, 0, 0";
            };
            reserved = lib.mkOption {
              type = with lib.types; nullOr (either int (attrsOf int));
              description = ''
                Reserved area for hl.monitor() (CssGap format).
                Either an integer (all sides) or an attrset with optional
                top, right, bottom, left fields.
                Example: { left = 600; }
              '';
              default = null;
            };
            scale = lib.mkOption {
              type = float;
              description = ''
                scale of the interface
              '';
              default = 1.0;
            };
            transform = lib.mkOption {
              type = int;
              description = ''
                  0 -> normal (no transforms)
                  1 -> 90 degrees
                  2 -> 180 degrees
                  3 -> 270 degrees
                  4 -> flipped
                  5 -> flipped + 90 degrees
                  6 -> flipped + 180 degrees
                  7 -> flipped + 270 degrees
              '';
              default = 0;
            };
            workspaces = lib.mkOption {
              type = listOf int;
              description = "List of workspaces";
            };
            workspace_names = lib.mkOption {
              type = listOf str;
              description = "List of workspace string names";
            };
          };
        });
      default = [ ];
      description = ''
          # Config for the hyprland monitors
          # https://wiki.hyprland.org/Configuring/Monitors/
          # 
          # monitorv2 = (lib.forEach displays
          #   ({display_name_output, mode, position, addreserved, scale, transform, ... }: {
          #     output = display_name_output;
          #     inherit mode position addreserved scale transform;
          #   })
          # );
          # 
          # Example:
          # output = "DP-2";
          # mode = "3440x1440@200";
          # position = "0x0";
          # addreserved = "1600, 0, 0, 0";
          # scale = 1;
          # transform = 3;
        '';
    };

    hyprland = {
      autostart = lib.mkEnableOption "Autostart hyprland from tty" // {
        default = true;
      };
      lock = lib.mkEnableOption "locking of host" // { default = isLaptop; };
      qtile = lib.mkEnableOption "qtile like behavior for workspaces";
      plugin = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum [ "hyprnstack" ]);
        description = "Plugin to enable for hyprland";
        default = null;
      };
    };

    waybar = {
      enable = lib.mkEnableOption "waybar" // { default = hyprlandCfg.enable; };
      hwmon = lib.mkOption {
        type = lib.types.str;
        default = "/sys/class/hwmon/hwmon0/temp1_input";
        description = "Temperature monitor device file";
      };
      config = lib.mkOption {
        type =
          lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description =
          "Additional waybar config (wallust templating can be used)";
      };
      idle-inhibitor = lib.mkEnableOption "Idle inhibitor" // {
        default = host == "desktop";
      };
      persistent-workspaces = lib.mkEnableOption "Persistent workspaces" // {
        default = true;
      };
      hidden = lib.mkEnableOption "Hidden waybar by default";
    };
  };
}

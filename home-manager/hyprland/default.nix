{ config, host, lib, pkgs, ... }:
let inherit (config.custom) displays display;
in {
  imports = [
    ./idle.nix
    ./keybinds.nix
    ./lock.nix
    ./screenshot.nix
    ./startup.nix
    ./wallpaper.nix
    ./waybar.nix
  ];

  config = lib.mkIf config.wayland.windowManager.hyprland.enable {

    home = {
      sessionVariables = {
        HYPR_LOG = "/tmp/hyprland.log";
        WLR_NO_HARDWARE_CURSORS = 1;
        ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      };

      packages = with pkgs; [
        # hyprland shader switcher
        hyprshade

        # clipboard history
        cliphist
        wl-clipboard
      ];

      # shaders location config
      file.".config/hypr/shaders".source = ./shaders;

      # FIX bug with input
      # https://github.com/hyprwm/Hyprland/issues/5815
      file.".config/fcitx5/conf/waylandim.conf".text = "PreferKeyEvent=False";
    };

    # Hyprland plugins go here
    wayland.windowManager.hyprland.plugins = [
      # touchscreen plugin
      # inputs.hyprgrass.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    wayland.windowManager.hyprland.configType = "lua";
    wayland.windowManager.hyprland.settings = {

      monitor = (lib.forEach displays
        ({ display_name_output, mode ? "preferred", position ? "auto", reserved ? null, scale ? 1.0, transform ? 0, ... }:
          { output = display_name_output; inherit mode position scale transform; }
          // lib.optionalAttrs (reserved != null) { inherit reserved; }
        )
      );

      env = [
        { _args = ["HYPRCURSOR_THEME" config.home.pointerCursor.name]; }
        { _args = ["HYPRCURSOR_SIZE" (toString config.home.pointerCursor.size)]; }
      ];

      config = {
        input = {
          sensitivity = config.custom.mouse_sensitivity;
          kb_layout = config.custom.kbLayout;
          follow_mouse = 1;
          mouse_refocus = false;
          accel_profile = "flat";
          repeat_delay = 300;

          # Set config.custom.display setting index to specify which monitor is a touchscreen device via host specific configuration
          # touchdevice = lib.mkIf display.touchDevice.enabled {
          #   enabled = true;
          #   transform = display.touchDevice.transform;
          #   output =
          #     (lib.elemAt displays display.touchDevice.devIndex).display_name_output;
          # };

          touchpad = {
            natural_scroll = true;
            disable_while_typing = true;
            scroll_factor = 0.2;
          };
        };

        # hyprgrass touchscreen plugin settings
        # plugin.touch_gestures = {
        #   sensitivity = 3.0;
        #   workspace_swipe_fingers = 3;
        #   workspace_swipe_edge = false;
        #   long_press_delay = 400;
        # };

        general = let gap = if host == "desktop" then 0 else 2;
        in {
          gaps_in = gap;
          gaps_out = gap;
          border_size = 3;
          layout = "master";
        };

        decoration = {
          rounding = 0;
          shadow = {
            enabled = host != "vm";
            range = 4;
            render_power = 3;
            color = "rgba(1a1a1aee)";
          };

          # dim_inactive = true
          # dim_strength = 0.05

          blur = {
            # enabled = host != "vm";
            enabled = false;
            size = 2;
            passes = 3;
            new_optimizations = true;
          };
        };

        animations = {
          enabled = false;
        };

        dwindle = {
          preserve_split = true;
          force_split = 2;
        };

        master = {
          new_on_active = "none";
          mfact = 0.5;
          orientation = "left";
          smart_resizing = true;
        };

        binds = { workspace_back_and_forth = false; };

        misc = {
          vrr = 1;
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          force_default_wallpaper = 0;
          mouse_move_enables_dpms = false;
          animate_manual_resizes = true;
          animate_mouse_windowdragging = true;
          key_press_enables_dpms = true;
          enable_swallow = false;
          swallow_regex = "^([Kk]itty|[Ww]ezterm)$";
          focus_on_activate = false;
          background_color = "0x383539";
        };

        debug.disable_logs = false;
      };

      # bind workspaces to monitors
      workspace_rule = pkgs.custom.lib.mapWorkspaces
        ({ workspace, monitor, workspace_name, ... }: {
          workspace = toString workspace;
          inherit monitor;
          default_name = workspace_name;
        })
        displays;

      window_rule = [
        # { match.class = "Shijima-Qt"; no_blur = true; }
        # { match.class = "Shijima-Qt"; decorate = false; }
        # { match.class = "Shijima-Qt"; no_shadow = true; }
        # { match.class = "Shijima-Qt"; float = true; }
        # { match.class = "Shijima-Qt"; pin = true; }

        { match.class = "(.*menu.*)"; float = true; }
        { match.class = "(.*Minecraft.*)"; float = true; }
        { match.fullscreen = true; border_size = 5; }        # monocle mode
        { match.class = "wlroots"; float = true; }           # hyprland debug session
        { match.class = "Waydroid"; float = true; }
        { match.class = "(?i)qjackctl"; float = true; size = "40% 20%"; }
        { match.class = "ayaka-gui"; float = true; }
        { match.class = "org.fcitx."; float = true; }
        { match.class = "fl64.exe"; float = true; }
        { match.class = "blender"; float = true; }
        { match.class = "anki"; float = true; }
        { match.class = "SnekStudio"; decorate = false; }
        # do not idle while watching videos
        { match.class = "librewolf"; idle_inhibit = "focus"; }
        { match.class = "YouTube"; idle_inhibit = "focus"; }
        { match.class = "mpv"; idle_inhibit = "focus"; }
        { match.class = "REAPER"; idle_inhibit = "focus"; }
        # { match.class = "^(REAPER)$"; stay_focused = true; }
      ];
    };

    wayland.windowManager.hyprland.extraConfig = ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("wl-paste --watch cliphist store")
      end)
    '';

    # hyprland crash reports
    custom.persist = { home.directories = [ ".cache/hyprland" ]; };
  };
}

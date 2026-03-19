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

    wayland.windowManager.hyprland.importantPrefixes = [ "output" ];
    wayland.windowManager.hyprland.settings = {
      # monitor = (lib.forEach displays
      #   ({ display_name, hyprland, ... }: "${display_name}, ${hyprland}"))
      #   ++ (lib.optional (host != "desktop") ",preferred,auto,auto");

      # monitorv2 = {
      #   output = "DP-2";
      #   mode = "3440x1440@200";
      #   position = "0x0";
      #   addreserved = "1600, 0, 0, 0";
      #   scale = 1;
      #   transform = 3;
      # };

      monitorv2 = (lib.forEach displays
        ({display_name_output, mode, position, addreserved, scale, transform, ... }: {
          output = display_name_output;
          inherit mode position addreserved scale transform;
        })
      );

      env = [
        "HYPRCURSOR_THEME,${config.home.pointerCursor.name}"
        "HYPRCURSOR_SIZE,${toString config.home.pointerCursor.size}"
      ];

      input = {
        sensitivity = config.custom.mouse_sensitivity;
        kb_layout = config.custom.kbLayout;
        follow_mouse = 0;
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
      # The default sensitivity is probably too low on tablet screens,
      # I recommend turning it up to 4.0
      # sensitivity = 3.0;

      # must be >= 3
      # workspace_swipe_fingers = 3;

      # switching workspaces by swiping from an edge, this is separate from workspace_swipe_fingers
      # and can be used at the same time
      # possible values: l, r, u, or d
      # to disable it set it to anything else
      # workspace_swipe_edge = false;

      # in milliseconds
      # long_press_delay = 400;

      # experimental {
      #   # send proper cancel events to windows instead of hacky touch_up events,
      #   # NOT recommended as it crashed a few times, once it's stabilized I'll make it the default
      #   send_cancel = 0;
      # }
      # };

      # "$mod" = config.custom.hyprland.modkey;

      "$mainMod" = "SUPER";

      "$term" = "${config.custom.terminal.exec}";

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

        # blurls = rofi
      };

      animations = {
        enabled = false;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
        force_split = 2;
      };

      master = {
        new_on_active = false;
        mfact = "0.5";
        orientation = "left";
        smart_resizing = true;
      };

      binds = { workspace_back_and_forth = false; };

      misc = {
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

      # bind workspaces to monitors
      workspace = pkgs.custom.lib.mapWorkspaces
        ({ workspace, monitor, workspace_name, ... }:
          "${workspace}, monitor:${monitor}, defaultName:${workspace_name}")
        displays;

      windowrule = [
        # Shijima QT (still commented)
        # "match:class Shijima-Qt, no_blur on"
        # "match:class Shijima-Qt, decorate off"

        # "match:class Shijima-Qt, no_shadow on"
        # "match:class Shijima-Qt, float on"
        # "match:class Shijima-Qt, no_dim on"
        # "match:class Shijima-Qt, pin on"

        # "match:floating 1, dim_around on"            # old dimaround

        "match:class (.*menu.*), float on"
        "match:class (.*Minecraft.*), float on"
        "match:fullscreen 1, border_size 5"            # monocle mode
        "match:class wlroots, float on"                # hyprland debug session
        "match:class Waydroid, float on"
        "match:class QjackCtl, float on"
        "match:class ayaka-gui, float on"
        "match:class org.fcitx., float on"
        "match:class fl64.exe, float on"
        "match:class blender, float on"
        "match:class anki, float on"

        "match:class SnekStudio, decorate off"

        # do not idle while watching videos
        "match:class librewolf, idle_inhibit focus"
        "match:class YouTube, idle_inhibit focus"
        "match:class mpv, idle_inhibit focus"
        "match:class REAPER, idle_inhibit focus"
      ];

      exec-once = [
        # clipboard manager
        "wl-paste --watch cliphist store"
      ];
      # source = "~/.config/hypr/hyprland-test.conf";
    };
    # hyprland crash reports
    custom.persist = { home.directories = [ ".cache/hyprland" ]; };
  };
}

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  focal = inputs.focal.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
    ocr = true;
  };
  iso8601 = "%Y-%m-%dT%H:%M:%S%z";
  # screenshot with rofi options to preselect
in {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    home.packages =
      with pkgs; [
        swappy
        wf-recorder
        focal
      ];


    # swappy conf
    xdg.configFile."swappy/config".text = lib.generators.toINI { } {
      default = {
        save_dir = "${config.xdg.userDirs.pictures}/Screenshots";
        save_filename_format = "${iso8601}";
        show_panel = false;
        line_size = 5;
        text_size = 20;
        paint_mode = "brush";
        early_exit = false;
        fill_shape = false;
      };
    };

    custom.waybar = {
      config = {
        "custom/focal" = {
          exec = # sh
            ''focal-waybar --recording "󰑋"'';
          format = "{}";
          # hide-empty-text = true;
          # return-type = "json";
          on-click = "focal video --stop";
          interval = 2; # poll every 2s
        };

        modules-left = lib.mkBefore [ "custom/focal" ];
      };
    };

    wayland.windowManager.hyprland.settings = {
      bind = [
        # "SUPER, backslash, exec, grimblast --notify --freeze copy area"
        # "SUPER_SHIFT, backslash, exec, hypr-screenshot"
        # "SUPER_CTRL, backslash, exec, hypr-ocr"
      "SUPER_SHIFT, backslash, exec, focal image --area selection --no-notify --no-save --no-rounded-windows"
      "SUPER, backslash, exec, focal image --edit swappy --rofi --no-rounded-windows"
      "SUPER_CTRL, backslash, exec, focal image --area selection --ocr"
      ''ALT, backslash, exec, focal video --rofi --no-rounded-windows''
      ];
    };
  };
}

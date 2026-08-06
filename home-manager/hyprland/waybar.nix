{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.custom.waybar;
in
lib.mkIf cfg.enable {
  programs.waybar = {
    enable = true;
    # do not use the systemd service as it is flaky and unreliable
    # https://github.com/nix-community/home-manager/issues/3599
  };

  # toggle / launch waybar
  wayland.windowManager.hyprland.settings.bind = [
    "SUPER, v, exec, pkill waybar"
    "SUPER_SHIFT, v, exec, waybar"
  ];

  custom = {
    shell.packages = {
      brightness-ddc = pkgs.writeShellApplication {
        name = "brightness-ddc";
        runtimeInputs = with pkgs; [ ddcutil coreutils gnugrep ];
        text = ''
          #!/usr/bin/env bash

          get_current_brightness() {
            ddcutil getvcp 10 | grep -oP 'current value = +\K[0-9]+'
          }

          case "$1" in
            get)
              get_current_brightness
              ;;
            set)
              value="$2"
              for i in $(seq 1 "$(ddcutil detect --brief | grep -c '^Display')"); do
                ddcutil --sleep-multiplier=0 --display "$i" setvcp 10 "$value"
              done
              ;;
            toggle)
              current=$(get_current_brightness)
              if [ "$current" -gt 50 ]; then
                ddcutil setvcp 10 0
              else
                ddcutil setvcp 10 100
              fi
              ;;
            up)
              delta="$2"
              current=$(get_current_brightness)
              new=$((current + delta))
              [ "$new" -gt 100 ] && new=100
              ddcutil setvcp 10 "$new"
              ;;
            down)
              delta="$2"
              current=$(get_current_brightness)
              new=$((current - delta))
              [ "$new" -lt 0 ] && new=0
              ddcutil setvcp 10 "$new"
              ;;
            *)
              echo "Usage: brightness-ddc {get|set <value>|toggle|up <value>|down <value>}"
              exit 1
              ;;
          esac
        '';
      };

    };

    waybar.config =
      let
        alertSpan = s: ''<span color="{{color4}}">${s}</span>'';
        displays = config.custom.displays;
      in
      {
        backlight = {
          format = "{icon}   {percent}%";
          format-icons = [
            "󰃞"
            "󰃟"
            "󰃝"
            "󰃠"
          ];
          # on-scroll-down = "${lib.getExe pkgs.brightnessctl} s 1%-";
          # on-scroll-up = "${lib.getExe pkgs.brightnessctl} s +1%";
        };

        output = [ (lib.head displays).display_name_output ];

        battery = lib.mkIf config.custom.battery.enable {
          format = "{icon}    {capacity}%";
          format-charging = "     {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          states = {
            critical = 20;
          };
          tooltip = false;
        };

        clock = {
          calendar = {
            actions = {
              on-click-right = "mode";
              on-scroll-down = "shift_down";
              on-scroll-up = "shift_up";
            };
            format = {
              days = "<span color='{{color4}}'><b>{}</b></span>";
              months = "<span color='{{foreground}}'><b>{}</b></span>";
              today = "<span color='{{color3}}'><b><u>{}</u></b></span>";
              weekdays = "<span color='{{color5}}'><b>{}</b></span>";
            };
            mode = "year";
            mode-mon-col = 3;
            on-scroll = 1;
          };
          format-alt = "󰥔 {:%H:%M:%S-%Z %Y-%m-%d}";
          format = "󰥔 {:%H:%M:%S 󰸗 %a, %d %b %Y} ";
          # format = "󰥔   {:%H:%M}";
          # format-alt = "  {:%a, %d %b %Y}";
          interval = 1;
          tooltip-format = "<tt><small>{calendar}</small></tt>";
        };

        memory = {
          interval = 1;
          format = "{used:0.1f}G|{total:0.1f}G ";
        };
        cpu = {
          interval = 1;
          format = "{usage}|{load} ";
        };

        temperature = {
          hwmon-path = cfg.hwmon;
          interval = 1;
          format = "{temperatureC}°C ";
        };

        "custom/nix" = {
          format = "󱄅";
          on-click = "hypr-wallpaper";
          on-click-right = "wallpapers-select";
          tooltip = false;
        };

        "custom/shade" = {
          format = "";
          on-click = "hyprshade on blue-light-filter";
          # on-click-right = "hyprshade on vibrance";
          on-click-right = "hyprshade on blue-light-filter2";
          on-click-middle = "hyprshade off";
          tooltip = false;
        };
        "custom/brightness-ddc" = {
          format = "󰃠 {}%";
          interval = 10;
          exec = "${lib.getExe config.custom.shell.packages.brightness-ddc} get";
          on-click-right = "${lib.getExe config.custom.shell.packages.brightness-ddc} set 100";
          on-click = "${lib.getExe config.custom.shell.packages.brightness-ddc} set 0";
          on-click-middle = "${lib.getExe config.custom.shell.packages.brightness-ddc} toggle";
          on-scroll-down = "${lib.getExe config.custom.shell.packages.brightness-ddc} down 20";
          on-scroll-up = "${lib.getExe config.custom.shell.packages.brightness-ddc} up 20";
          tooltip = false;
        };


        idle_inhibitor = lib.mkIf cfg.idle-inhibitor {
          format = "{icon}";
          format-icons = {
            activated = alertSpan "";
            deactivated = "";
          };
        };

        # "hyprland/workspaces" = {
          # TODO: pacman, remove active inverse circle
          # format = "{icon}";
          # format-icons = {
          #   active = "󰮯";
          #   default = "·";
          #   urgent = "󰊠";
          # };
        # };

        "hyprland/window" = {
          rewrite = {
            # strip the application name
            "(.*) - (.*)" = "$1";
          };
          separate-outputs = true;
        };

        layer = "top";
        margin-right = "600";

        modules-center = [ "hyprland/workspaces"  ];

        modules-left = [
          "clock" 
          "memory"
          "temperature"
          "cpu"
          "network"
          "pulseaudio"
          "backlight"
          "custom/shade"
          "custom/brightness-ddc"
          "custom/nix"
          "tray"
        ] ++ (lib.optional cfg.idle-inhibitor "idle_inhibitor") ++ [  ];

        tray = { };

        modules-right =
          [
            "hyprland/window"
          ]
          ++ (lib.optional config.custom.battery.enable "battery")
          ++ [ "clock" ];

        network =
          {
            format-disconnected = alertSpan "󰖪    Offline";
            tooltip = false;
          }
          // (
            if config.custom.wifi.enable then
              {
                format = "    {essid}";
                on-click = "${config.xdg.configHome}/rofi/rofi-wifi-menu";
                on-click-right = "${config.custom.terminal.exec} nmtui";
              }
            else
              { format-ethernet = ""; }
          );

        position = "top";

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-icons = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
          format-muted = alertSpan "󰖁  Muted";
          on-click = "${lib.getExe pkgs.pamixer} -t";
          on-click-right = "pavucontrol";
          scroll-step = 1;
          tooltip = false;
        };

        start_hidden = cfg.hidden;
      };

    wallust = {
      nixJson.persistent_workspaces = cfg.persistent-workspaces;

      templates = {
        "waybar.jsonc" = {
          text = lib.strings.toJSON cfg.config;
          target = "${config.xdg.configHome}/waybar/config.jsonc";
        };
        "waybar.css" =
          let
            margin = "5px";
            baseModuleCss = ''
              font-family: ${config.custom.fonts.monospace};
              font-weight: bold;
              color: {{foreground}};
              transition: none;
              color: #fecdb2;
              text-shadow: 1px 1px 2px rgba(0,0,0,0.8);
              border-bottom:  1px solid transparent;
              padding-left: ${margin};
              padding-right: ${margin};
            '';
            mkModuleClassName =
              mod:
              "#${
                lib.replaceStrings
                  [
                    "hyprland/"
                    "/"
                  ]
                  [
                    ""
                    "-"
                  ]
                  mod
              }";
            mkModulesCss =
              arr:
              lib.concatMapStringsSep "\n" (mod: ''
                ${mkModuleClassName mod} {
                  ${baseModuleCss}
                }'') arr;
          in
          {
            text =
              ''
                * {
                  border: none;
                  border-radius: 0;
                }

                #waybar {
                  background: rgba(0,0,0,0.0);
                  font-size: 14px;
                  color: #fecdb2;
                }

                ${mkModulesCss cfg.config.modules-left}
                ${mkModulesCss cfg.config.modules-center}
                ${mkModulesCss cfg.config.modules-right}


                ${mkModuleClassName "custom/nix"} {
                  font-size: 20px;
                }

                ${mkModuleClassName "hyprland/workspaces"} * {
                  font-size: 14px;
                }

                #workspaces button {
                  ${baseModuleCss}
                  padding-left: 4px;
                  padding-right: 4px;
                }

                #workspaces button.active {
                  border-top:  1px solid black;
                  color: black;
                  background-color: rgba(255,255,255, 0.85);
                  transition: 200ms;
                  transition-duration: 200ms;
                }
              ''
              + lib.optionalString cfg.idle-inhibitor ''
                ${mkModuleClassName "idle_inhibitor"} {
                  font-size: 16px;
                }
              ''
              +
                # remove padding for the outermost modules
                ''
                  ${mkModuleClassName (lib.head cfg.config.modules-left)} {
                    padding-left: 0;
                    margin-left: ${margin};
                  }
                  ${mkModuleClassName (lib.last cfg.config.modules-right)} {
                    padding-right: 0;
                    margin-right: ${margin};
                  }
                '';
            target = "${config.xdg.configHome}/waybar/style.css";
          };
      };
    };
  };
}

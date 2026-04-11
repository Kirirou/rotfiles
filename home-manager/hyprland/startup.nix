{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  openOnWorkspace = workspace: program: "[workspace ${toString workspace} silent] ${program}";
in {
  # start hyprland
  custom.shell.profileExtra = lib.mkIf (config.wayland.windowManager.hyprland.enable && config.custom.hyprland.autostart) ''
    if [ "$(tty)" = "/dev/tty1" ]; then
      exec Hyprland &> /dev/null
    fi
  '';

  wayland.windowManager.hyprland.settings = {
    exec-once = [
      # init ipc listener
      "hypr-ipc &"

      # browsers
      # (openOnWorkspace 1 "brave --incognito")
      # (openOnWorkspace 1 "brave --profile-directory=Default")

      # firefox
      (openOnWorkspace 5 "librewolf")

      # (openOnWorkspace 12 "$term sh -c 'tenki --fps 60 --tps 60 --show-fps --timer-color yellow --mode rain; exec fish'")

      # Open Discord
      (openOnWorkspace 1 "vesktop")

      # Open Steam
      # (openOnWorkspace 5 "steam")

      # audio
      (openOnWorkspace 13 "pavucontrol")
      # (openOnWorkspace 9 "easyeffects")

      # (openOnWorkspace 9 "easyeffects")

      # download desktop
      (openOnWorkspace 10 "${lib.getExe pkgs.kitty} ~/_CURRENT")
      (openOnWorkspace 10 "nemo ~/_CURRENT")
      (openOnWorkspace 10 "transmission-remote-gtk")
      (openOnWorkspace 10 "liferea")
      # (openOnWorkspace 10 "hyprctl dispatch layoutmsg orientationcycle left top")

      # Telegram
      (openOnWorkspace 8 "telegram-desktop")

      (openOnWorkspace 3 ''nix run nixpkgs#st fish'')

      # focus the initial workspaces on startup
      "hyprctl dispatch workspace 1"
      "hyprctl dispatch workspace 4"

      "swww-daemon &"
      "swww img ~/Pictures/Wallpapers/nix-wide.png &"
      # "mpvpaper -s -o \"no-audio loop\" DP-3 ~/Videos/timelapce_bw.mp40001-1087.mkv &"
      "wallust theme base16-embers &"
      "waybar &"

      # fix gparted "cannot open display: :0" error
      "${lib.getExe pkgs.xhost} +local:${user}"
      # fix Authorization required, but no authorization pcustomocol specified error
      # "${pkgs.xhost}/bin/xhost si:localuser:root"

      # stop fucking with my cursors
      "hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}"

      # start polkit agent
      "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &"

      # Start input engine fcitx5
      "fcitx5 &"
      "pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name=virtualmic channel_map=front-left,front-right &"
      "pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name=lipsync channel_map=front-left,front-right &"
    ];
  };
}

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

  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("hypr-ipc &")
      hl.exec_cmd("${openOnWorkspace 5 "librewolf"}")
      hl.exec_cmd("${openOnWorkspace 1 "vesktop"}")
      hl.exec_cmd("${openOnWorkspace 13 "pavucontrol"}")
      hl.exec_cmd("${openOnWorkspace 10 "${lib.getExe pkgs.kitty} ~/_CURRENT"}")
      hl.exec_cmd("${openOnWorkspace 10 "nemo ~/_CURRENT"}")
      hl.exec_cmd("${openOnWorkspace 10 "transmission-remote-gtk"}")
      hl.exec_cmd("${openOnWorkspace 10 "liferea"}")
      hl.exec_cmd("${openOnWorkspace 8 "telegram-desktop"}")
      hl.exec_cmd("${openOnWorkspace 3 "nix run nixpkgs#st fish"}")
      hl.exec_cmd("hyprctl dispatch workspace 1")
      hl.exec_cmd("hyprctl dispatch workspace 4")
      hl.exec_cmd("${lib.getExe pkgs.swaybg} -c '#383539' &")
      hl.exec_cmd("wallust theme base16-embers &")
      hl.exec_cmd("waybar &")
      hl.exec_cmd("${lib.getExe pkgs.xhost} +local:${user}")
      hl.exec_cmd("hyprctl setcursor ${config.home.pointerCursor.name} ${toString config.home.pointerCursor.size}")
      hl.exec_cmd("${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1 &")
      hl.exec_cmd("fcitx5 &")
      hl.exec_cmd("pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name=virtualmic channel_map=front-left,front-right &")
      hl.exec_cmd("pactl load-module module-null-sink media.class=Audio/Source/Virtual sink_name=lipsync channel_map=front-left,front-right &")
    end)
  '';
}

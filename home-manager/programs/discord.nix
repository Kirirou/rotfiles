{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.custom.discord.enable {
    home.packages = [
      pkgs.zoom-us
      pkgs.irssi
      pkgs.weechat
      pkgs.sic
      (pkgs.writeShellApplication {
        name = "discord-vesktop";
        text = ''
          env -u NIXOS_OZONE_WL vesktop --use-gl=desktop
        '';
      })
      (pkgs.makeDesktopItem {
        name = "discord-vesktop";
        exec = "env -u NIXOS_OZONE_WL vesktop --use-gl=desktop";
        desktopName = "Discord-Vesktop";
        icon = "${pkgs.tela-circle-icon-theme}/share/icons/Tela-circle/scalable/apps/discord.svg";
      })

      (pkgs.writeShellApplication {
        name = "discord-fix";
        text = ''
          env ELECTRON_OZONE_PLATFORM_HINT= ${lib.getExe pkgs.discord}
        '';
      })
      (pkgs.makeDesktopItem {
        name = "discord-fix";
        exec = "env ELECTRON_OZONE_PLATFORM_HINT= ${lib.getExe pkgs.discord}";
        desktopName = "Discord-Fix";
        icon = "${pkgs.tela-circle-icon-theme}/share/icons/Tela-circle/scalable/apps/discord.svg";
      })

      pkgs.discord
    ];

    custom.persist = {
      home.files = [
        ".config/zoomus.conf"
        ".config/zoom.conf"
      ];
      home.directories = [
        ".config/discord"
        ".config/vesktop"
        ".config/VencordDesktop"
        ".zoom"
      ];
    };
  };
}

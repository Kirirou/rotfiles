{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.custom.minecraft-launchers.enable {
    home.packages = with pkgs; [
      # Launcher Java
      prismlauncher
      mcpelauncher-ui-qt
      cubiomes-viewer
      modrinth-app
      jdk17
      jdt-language-server
    ];

    custom.persist = {
      home.directories = [
        ".local/share/PrismLauncher/"
        ".local/share/mcpelauncher/"
        ".gradle"
      ];
    };
  };
}

{
  host,
  isNixOS,
  lib,
  pkgs,
  ...
}:
{
  options.custom = {
    hyprland = {
      modkey = lib.mkOption {
        type = lib.types.str;
        default = "SUPER";
      };
    };

    irc.enable = lib.mkEnableOption "senpai" // {
      default = false;
    };
    discord.enable = lib.mkEnableOption "discord" // {
      default = false;
    };
    insomnia.enable = lib.mkEnableOption "discord" // {
      default = true;
    };
    firefox.enable = lib.mkEnableOption "firefox" // {
      default = true;
    };
    rofi.enable = lib.mkEnableOption "rofi" // {
      default = true;
    };
    k3b.enable = lib.mkEnableOption "k3b" // {
      default = false;
    };
    kiwix.enable = lib.mkEnableOption "k3b" // {
      default = false;
    };
    telegram.enable = lib.mkEnableOption "telegram-desktop" // {
      default = false;
    };
    reaper.enable = lib.mkEnableOption "reaper" // {
      default = false;
    };
    xmrig.enable = lib.mkEnableOption "xmrig mining user service (manual start only)" // {
      default = false;
    };
    blender.enable = lib.mkEnableOption "blender" // {
      default = false;
    };
    deadbeef.enable = lib.mkEnableOption "deadbeef" // {
      default = false;
    };
    helix.enable = lib.mkEnableOption "helix" // {
      default = true;
    };
    kitty.enable = lib.mkEnableOption "kitty" // {
      default = true;
    };
    obs-studio.enable = lib.mkEnableOption "obs-studio" // {
      default = isNixOS && host == "desktop";
    };
    rclip.enable = lib.mkEnableOption "rclip";
    vlc.enable = lib.mkEnableOption "vlc";

    # MINECRAFT PRISMLAUNCHER
    minecraft-launchers.enable = lib.mkEnableOption "minecraft-prismlauncher + others?" // {
      default = false;
    };
    # WALLUST
    wallust = with lib.types; {
      enable = lib.mkEnableOption "wallust" // {
        default = true;
      };
      colorscheme = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "The colorscheme to use. If null, will use the default colorscheme from the wallpaper.";
      };
      nixJson = lib.mkOption {
        type = lib.types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Data to be written to nix.json for use in other programs at runtime.";
      };
      templates = lib.mkOption {
        type = attrsOf (submodule {
          options = {
            text = lib.mkOption {
              type = str;
              description = "Content of the template file";
            };
            target = lib.mkOption {
              type = str;
              description = "Absolute path to the file to write the template (after templating), e.g. ~/.config/dunst/dunstrc";
            };
          };
        });
        default = [ ];
        description = ''
          Example templates, which are just a file you wish to apply `wallust` generated colors to.
          template = "dunstrc"
        '';
      };
    };
  };
}

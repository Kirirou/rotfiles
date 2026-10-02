{
  pkgs,
  config,
  lib,
  user,
  inputs,
  ...
}: let
  firefoxPkg = pkgs.firefox;
in {
  config = {
    home.packages = with pkgs; [ librewolf ];

    # The VAAPI plumbing (nvidia-vaapi-driver, LIBVA_DRIVER_NAME, etc.) is
    # set up system-wide in nixos/nvidia.nix, but LibreWolf doesn't
    # self-enable hardware video decode on Linux - without this it silently
    # falls back to software decode for every video.
    home.file.".librewolf/rot/user.js".text = ''
      user_pref("media.ffmpeg.vaapi.enabled", true);
      user_pref("media.hardware-video-decoding.enabled", true);
      user_pref("media.hardware-video-decoding.force-enabled", true);
    '';
    programs = lib.mkIf config.custom.firefox.enable {
      # firefox
      firefox = {
        enable = true;
        package = firefoxPkg;
        configPath = ".mozilla/firefox";

        profiles.${user} = {
          # TODO: define keyword searches here?
          # search.engines = [ ];
        };
      };
    };
    # set default browser
    xdg.mimeApps = let 
      browser = "librewolf.desktop";
    in {
      defaultApplications = {
        "x-scheme-handler/http" = browser;
        "text/html" = browser;
        "text/xml" = browser;
        "application/xhtml_xml" = browser;
        "image/webp" = lib.getExe pkgs.imv;
        "image/jpeg" = lib.getExe pkgs.imv;
        "image/png" = lib.getExe pkgs.imv;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/ftp" = browser;
      };
      associations.added = {
        "text/html" = browser;
        "text/xml" = browser;
        "application/xhtml_xml" = browser;
        "image/webp" = browser;
        "x-scheme-handler/https" = browser;
        "x-scheme-handler/ftp" = browser;
      };
    };

    custom.persist = {
      home.directories = [
        ".cache/mozilla"
        ".mozilla"
        ".config/firefox"
        ".config/librewolf"
        ".librewolf"
        ".cache/librewolf"
      ];
    };
  };
}

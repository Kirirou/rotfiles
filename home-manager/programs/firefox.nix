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

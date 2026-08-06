{
  user,
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./hyprland
    ./programs
    ./shell
  ];

  # setup fonts for other distros, run "fc-cache -f" to refresh fonts
  fonts.fontconfig = {
    enable = true;
  };

  services.udiskie = {
    enable = true;
    tray = "never";   # Set to "never" if you don’t want a tray icon
    notify = true;   # Show notifications when devices are mounted
  };

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    # do not change this value
    stateVersion = "23.05";

    sessionVariables = {
      __IS_NIXOS = "1";
      NIXPKGS_ALLOW_UNFREE = "1";
    };
    
    
    packages =
      with pkgs;
      [
        curl
        gzip
        wget
        killall
        rar # includes unrar
        zip # not includes unzip
        rsync
        sendme
        unzip
        p7zip
        lzip
        ripgrep
        libreoffice
        onlyoffice-desktopeditors
        zathura
        mupdf
        # digikam
        darktable
        trash-cli
        xdg-utils
        zenity
        lynx

        # mcomix
        # yacreader
        musescore

        nodejs
        custom.sysmocap
      ]
      ++ (lib.optional config.custom.helix.enable helix)
      ++ [ home-manager ]
      # handle fonts
      ++ config.custom.fonts.packages
      # add custom user created shell packages
      ++ (lib.attrValues config.custom.shell.finalPackages);
  };


  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # stop bothering me
  xdg = {
    enable = true;
    userDirs.enable = true;
    userDirs.setSessionVariables = true;
    mimeApps.enable = true;
    mimeApps.defaultApplications = {
      "application/pdf" = [ "org.pwmt.zathura.desktop" ];
      "text/plain" = [ "helix.desktop" ];
    };
  };

  custom.persist = {
    home.directories = [
      ".config/MuseScore"
      ".config/darktable"
      ".cache/MuseScore"
      ".config/onlyoffice"
    ];
    home.files = [ ".config/digikamrc" ".config/digikam_systemrc"];
  };
}

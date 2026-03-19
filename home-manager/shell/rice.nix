{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  home = {
    packages = with pkgs; [
      cool-retro-term
      sl
      libcaca
      oneko
      ninvaders
      asciiquarium
      bastet
      cbonsai
      cmatrix
      hollywood
      fastfetch
      cpufetch
      fortune
      cowsay
      imagemagick
      nitch
      pipes-rs
      scope-tui
      moon-buggy
      tokei
      tenki
      snowmachine
      ninvaders
      wl-color-picker
      umoria
      inputs.wfetch.packages.${pkgs.stdenv.hostPlatform.system}.wfetch
      # custom.wl_shimeji
      (pkgs.writeShellApplication {
        name = "bbb";
        runtimeInputs = [ pkgs.ddcutil ];
        text = ''
          if [ -z "$1" ] || [ "$1" -lt 0 ] || [ "$1" -gt 100 ]; then
            echo "Usage: bbb <0-100>"
            exit 1
          fi

          for i in $(seq 1 5); do
            sudo ddcutil --display "$i" setvcp 10 "$1"
          done
        '';
      })
    ];

    shellAliases = {
      neofetch = "${lib.getExe pkgs.fastfetch} --config neofetch";
      hw = "hypr-wallpaper";
    };
  };

  custom.persist = {
    home.directories = [
      ".local/share/wl_shimeji"
    ];
  };


  # create xresources
  xresources = {
    path = "${config.xdg.configHome}/.Xresources";
    properties = {
      "Xft.dpi" = 90;
      "Xft.antialias" = true;
      "Xft.hinting" = true;
      "Xft.rgba" = "rgb";
      "Xft.autohint" = false;
      "Xft.hintstyle" = "hintslight";
      "Xft.lcdfilter" = "lcddefault";

      "*.font" = "JetBrainsMono Nerd Font Mono:Medium:size=12";
      "*.bold_font" = "JetBrainsMono Nerd Font Mono:Bold:size=12";
    };
  };
}

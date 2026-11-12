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
      custom.csakura
      custom.terrascope
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
      xev # keycode/keysym lookup - useful for debugging WM keybinds under non-ANSI layouts
      snowmachine
      ninvaders
      wl-color-picker
      umoria
      inputs.wfetch.packages.${pkgs.stdenv.hostPlatform.system}.wfetch
      inputs.ie-r.packages.${pkgs.stdenv.hostPlatform.system}.default # instant color eyedropper
      inputs.late-sh.packages.${pkgs.stdenv.hostPlatform.system}.late
      # custom.wl_shimeji
      (pkgs.writeShellApplication {
        name = "bbb";
        runtimeInputs = [ pkgs.ddcutil pkgs.gnugrep pkgs.gawk ];
        text = ''
          if [ -z "$1" ] || [ "$1" -lt 0 ] || [ "$1" -gt 100 ]; then
            echo "Usage: bbb <0-100>"
            exit 1
          fi

          # ddcutil detect does a full I2C bus scan, which is slow (1-3s+).
          # Cache the display list instead of re-scanning on every call, since
          # this runs on every waybar scroll tick otherwise.
          cache="''${XDG_RUNTIME_DIR:-/tmp}/bbb-displays"
          if [ ! -s "$cache" ] || [ -n "$(find "$cache" -mmin +10 2>/dev/null)" ]; then
            ddcutil detect --terse | grep -oP '(?<=^Display )\d+' > "$cache"
          fi
          displays=$(cat "$cache")

          if [ -z "$displays" ]; then
            echo "bbb: no DDC/CI displays detected"
            exit 1
          fi

          # --sleep-multiplier shrinks ddcutil's conservative built-in protocol
          # delays, --noverify skips the read-back verification; both cut
          # per-call latency substantially. Run in parallel across monitors.
          for i in $displays; do
            ddcutil --display "$i" --sleep-multiplier 0.1 --noverify setvcp 10 "$1" \
              || echo "bbb: failed to set brightness on display $i" &
          done
          wait
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

{ pkgs, lib, inputs, config, ... }: {
  custom = {
    kbLayout = "jp";
    wifi.enable = true;
    backlight.enable = true;
    mouse_sensitivity = 0.5;


    # Config for the hyprland monitors
    # https://wiki.hyprland.org/Configuring/Monitors/
    # 
    # monitorv2 = (lib.forEach displays
    #   ({display_name_output, mode, position, addreserved, scale, transform, ... }: {
    #     output = display_name_output;
    #     inherit mode position addreserved scale transform;
    #   })
    # );
    # 
    # Example:
    # output = "DP-2";
    # mode = "3440x1440@200";
    # position = "0x0";
    # addreserved = "1600, 0, 0, 0";
    # scale = 1;
    # transform = 3;

    # first monitor in list gets selected for waybar to show only at that monitor
    displays = [
      {
        # left half: keys 1, 2, q, a, z, x all live here.
        #
        # Same physical ultrawide panel as HDMI-A-1 below, either whole
        # (single 5120x1440@144 output, PIP/PBP off, HDMI unplugged) or
        # split in half (this half becomes 2560x1440@60, PIP/PBP on). A
        # fixed "5120x1440@144" mode here only ever matched the first
        # state - in split mode DP-3 reports itself as a plain 2560x1440
        # panel over EDID and the fixed mode simply doesn't exist on the
        # output, so Hyprland would fail to apply it.
        #
        # First tried "preferred" - WRONG, confirmed live via `hyprctl
        # monitors`: this panel's EDID preferred-timing flag points at a
        # 1920x1080@60 compatibility fallback, not its native resolution,
        # even though "5120x1440@144.00Hz" is right there at the top of
        # its own availableModes list. A quirk of this specific monitor's
        # EDID, not something guessable from the config alone. "highres"
        # (confirmed from Hyprland's wiki: "use the highest supported
        # resolution") ignores that flag entirely and picks the actual
        # highest-resolution mode the panel is advertising right now -
        # 5120x1440@144 when whole, whatever the half-panel's true max is
        # when split - so this still adapts to either PBP state without
        # trusting the one EDID field that turned out to be wrong.
        display_name_output = "DP-3";
        mode = "highres";
        position = "0x0";
        scale = 1.0;
        transform = 0;
        workspace_names = [ "1" "2" "q" "a" "z" "x" ];
        workspaces = [ 1 2 5 8 11 12 ];
      }
      {
        # retired from the keyboard-row workspace scheme (not part of the
        # DP-3/HDMI-A-1 left-right split); still positioned/configured for
        # whenever it's actually connected, just no workspaces pinned to it.
        display_name_output = "DP-2";
        mode = "2560x1080@200";
        position = "2560x1440";
        reserved = { left = 600; };
        scale = 1.0;
        transform = 0;
        workspace_names = [ ];
        workspaces = [ ];
      }
      {
        # right half of the DP-3 ultrawide's split-PIP mode: same physical
        # panel, second input. Positioned immediately to the right of DP-3
        # at matching resolution/height so the cursor tracks correctly
        # across the seam instead of jumping to a stacked-below offset.
        # keys 3, 4, w, e, s, d, c all live here.
        # Same reasoning as DP-3 above - "highres" instead of a fixed
        # 2560x1440@60 or the EDID-unreliable "preferred", so this just
        # adapts whenever the output actually exists (split PBP mode)
        # instead of assuming a fixed mode or trusting that EDID flag.
        display_name_output = "HDMI-A-1";
        mode = "highres";
        position = "2560x0";
        scale = 1.0;
        transform = 0;
        workspace_names = [ "3" "4" "w" "e" "s" "d" "c" ];
        workspaces = [ 3 4 6 7 9 10 13 ];
      }
    ];
    terminal.size = 8;

    wallust.colorscheme = "base16-embers";

    hyprland = {
      modkey = "SUPER"; # could be "ALT"
      autostart = false;
      lock = false;
    };
    waybar = {
      enable = true;
      persistent-workspaces = true;
      hidden = false;
      # boot-stable symlink maintained by a udev rule in hosts/desktop/default.nix,
      # since hwmonN numbering for coretemp isn't fixed across boots
      hwmon = "/run/coretemp-temp1_input";
    };
    # Disabled - the headless mirror output this creates (home-manager/
    # hyprland/wayvnc.nix) was stealing workspaces (w, d, etc. became
    # unreachable) even after fixing the mirror relationship itself. wayvnc
    # can't run without some output to capture, so disabling it removes the
    # headless monitor entirely rather than leaving wayvnc crash-looping
    # with nothing to serve.
    wayvnc.enable = false;

    # Select touchscreen monitor by id
    # Find out monitor ID and names with "hyprctl monitors" command
    display.touchDevice = {
      enabled = true;
      # (Starts from 0) devIndex 0 is first monitor ID in "displays" list
      devIndex = 0;
      transform = 0;
      # ====== 0 horizontal
      # |||||| 1 vertical
    };

    vlc.enable = true;
    k3b.enable = false;

    kiwix.enable = true;

    blender.enable = true;
    reaper.enable = true;

    discord.enable = true;
    telegram.enable = true;

    insomnia.enable = true;
    minecraft-launchers.enable = true;

    irc.enable = true;

    # Select gpg keyid for git
    # keys located in ~/.local/share/.gnupg
    # To list the gpg signing keyid run:
    # gpg --list-secret-keys --keyid-format=long
    # Copy over id string after similar characters 'sec dsa2048/', text after '/'
    git = {
      enable = true;
      git-keyid = "80A56B918CFA5155";
    };

    persist = {
      home.files = [ ".config/kritarc" ".config/kritadisplayrc" ];
      home.directories = [ ".config/PureRef" ".config/dztui" ".local/share/Anki2" ".config/teams-for-linux" ".config/inkscape" ".local/share/love" ];
    };
  };
  home.file."Music".source = config.lib.file.mkOutOfStoreSymlink "/md/wdc-data/_SMALL/_MUSIC";

  xdg.userDirs.music = "/md/wdc-data/_SMALL/_MUSIC";

  home = {
    packages = with pkgs; [
      krita inkscape anki
      teamspeak6-client
      guvcview
      love
      inputs.dzgui.packages.${pkgs.stdenv.hostPlatform.system}.dzgui
      inputs.desktop-goose.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
    file.".local/share/applications/protontricks.desktop".text = ''
      [Desktop Entry]
      NoDisplay=true
    '';
  };
}

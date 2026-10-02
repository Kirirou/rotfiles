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
        display_name_output = "DP-3";
        mode = "5120x1440@144";
        wlr_mode = "5120x1440@143.996994";
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
        display_name_output = "HDMI-A-1";
        mode = "2560x1440@60";
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
    wayvnc.enable = true;

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

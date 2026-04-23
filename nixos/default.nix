{
  pkgs,
  config,
  lib,
  ...
}:
{
  imports = [
    # hardware
    ./hdds.nix
    ./nvidia.nix
    ./zfs.nix
    ./audio.nix
    ./keyd.nix
    ./sensors.nix
    ./vm.nix

    ./auth.nix
    ./samba.nix
    ./fileshare.nix
    ./monero.nix
    # ./sws.nix # need for later
    ./dns.nix
    ./pr_managment.nix
    ./nginx.nix
    ./configuration.nix
    ./wine.nix
    ./docker.nix
    ./llm.nix
    ./jellyfin.nix
    ./filezilla.nix
    ./flatpak.nix
    ./hyprland.nix
    ./impermanence.nix
    ./nix.nix
    ./plasma.nix
    ./sops.nix
    ./gh.nix
    ./transmission.nix
    ./users.nix
    ./surrealdb.nix
    ./minecraft
    ./steam.nix
    ./lutris.nix
    ./sleep.nix
    ./input.nix
    ./bluetooth.nix
    ./hotspot.nix
  ];

  config = {
    # automount disks
    services.gvfs.enable = true;
    # services.devmon.enable = true;
    programs.dconf.enable = true;

    environment = {
      etc = {
        # universal git settings
        "gitconfig".text = config.hm.xdg.configFile."git/config".text;
        # get gparted to use system theme
        "xdg/gtk-3.0/settings.ini".text = config.hm.xdg.configFile."gtk-3.0/settings.ini".text;
      };

      # install fish completions for fish
      # https://github.com/nix-community/home-manager/pull/2408
      pathsToLink = [ "/share/fish" ];

      variables = {
        TERMINAL = lib.getExe config.hm.custom.terminal.package;
        EDITOR = config.hm.custom.shell.defaultEditor;
        VISUAL = config.hm.custom.shell.defaultEditor;
        MANPAGER = config.hm.custom.shell.defaultEditor;
        NIXPKGS_ALLOW_UNFREE = "1";
        STARSHIP_CONFIG = "${config.hm.xdg.configHome}/starship.toml";
      };

      # use some shell aliases from home manager
      shellAliases = {
        inherit (config.hm.programs.bash.shellAliases)
          eza
          ls
          ll
          la
          lla
          ;
      }
      // {
        inherit (config.hm.home.shellAliases)
          # eza related

          t
          tree
          y # yazi
          ;
      };

      systemPackages =
        with pkgs;
        [
          vim
          iptables
          stdmanpages
          curl
          eza
          killall
          ntfs3g
          procps
          ripgrep
          htop
          iotop
          glib
          # jmtpfs
          # mtpfs
          iftop
          # ventoy
          stress
          stress-ng
          dmidecode
          memtester
          wget
          dig
          lsof
          nmap
          arp-scan
          wireshark
          dhcpcd
          netdiscover
          aria2
          speedtest-cli
          axel
          inetutils
          usbutils
          zellij
          efibootmgr
          powertop
          powerstat
          brightnessctl
          ddcutil
          smartmontools
          nvme-cli
          parted
          ddcutil
          sysstat
          scrcpy
          # cmake
          (python3.withPackages (
            ps: with ps; [
              # xdis
            ]
          ))

          glib
          gtk3
          nss
          nspr
          atk
          at-spi2-atk
          at-spi2-core
          mesa
          libdrm
          cups
          libxkbcommon
          alsa-lib
          pulseaudio
          libx11
          libxcomposite
          libxdamage
          libxfixes
          libxrandr
          libxcursor
          libxi
          libxtst

          gdb
          scanmem

          wayvnc

          jdk25

          poppler-utils
          cups-pdf-to-pdf
          sane-airscan
          simple-scan
          xsane
        ]
        ++
          # install gtk theme for root, some apps like gparted only run as root
          (with config.hm.gtk; [
            theme.package
            iconTheme.package
          ])
        # add custom user created shell packages
        ++ (lib.attrValues config.custom.shell.finalPackages)
        ++ (lib.optional config.hm.custom.helix.enable helix)
        ++ (lib.optional config.hm.custom.discord.enable vesktop);
    };

    # add custom user created shell packages to pkgs.custom.shell
    nixpkgs.overlays = [
      (_: prev: {
        custom = prev.custom // {
          shell = config.custom.shell.finalPackages // config.hm.custom.shell.finalPackages;
        };
      })
    ];

    # setup fonts
    fonts.packages = config.hm.custom.fonts.packages ++ [ pkgs.custom.rofi-themes ];

    programs = {
      # use same config as home-manager
      bash = {
        interactiveShellInit = config.hm.programs.bash.initExtra;
        loginShellInit = config.hm.programs.bash.profileExtra;
      };

      # bye bye nano
      nano.enable = lib.mkForce false;
    };

    # faster boot times
    # systemd.services.NetworkManager-wait-online.enable = false;

    systemd.services."user@".serviceConfig.Delegate = "cpu cpuset io memory pids";

    # use gtk theme on qt apps
    qt = {
      enable = true;
      platformTheme = null; # was "gnome", but disabling due to qgnomeplatform not building
      style = "adwaita-dark";
    };

    # fix opening terminal for nemo / thunar by using xdg-terminal-exec spec
    xdg.terminal-exec = {
      enable = true;
      settings = {
        default = [ "${config.hm.custom.terminal.package.pname}.desktop" ];
      };
    };

    custom.persist = {
      root.directories = lib.mkIf config.hm.custom.wifi.enable [ "/etc/NetworkManager" ];

      home.directories = [ ".local/state/wireplumber" ];
    };
  };
}

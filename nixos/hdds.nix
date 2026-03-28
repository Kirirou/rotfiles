{ lib, config, user, ... }:
let
  cfg = config.custom.hdds;
  home-dir = config.hm.home.homeDirectory;
  wdc-data-mountpoint = "/md/wdc-data";
  wdc-data-dataset = "wdc-blue/data";
  wdc-okii-mountpoint = "/md/wdc-okii";
  wdc-okii-dataset = "wdc-blue/okii";
in {
  config = lib.mkIf cfg.enable {
    # non os zfs disks
    boot.zfs.extraPools = [
      (lib.optionalString cfg.wdc1tb "wdc-blue")
    ];
    boot.kernelModules = [ "brd" ];
    boot.extraModprobeConfig = ''
      options brd rd_nr=1 rd_size=41943040
      options zfs zfs_arc_max=51539607552
    '';

    services = {
      sanoid = lib.mkIf config.custom.zfs.snapshots {
        enable = true;

        datasets = {
          ${wdc-data-dataset} = lib.mkIf cfg.wdc1tb {
            hourly = 24;
            daily = 31;
            weekly = 7;
            monthly = 1;
          };
          ${wdc-okii-dataset} = lib.mkIf cfg.wdc1tb {
            hourly = 12;
            daily = 14;
            weekly = 2;
            monthly = 1;
          };
        };
      };
    };

    custom.shell.packages = {
      zfs-destroy-dataset-snapshots = ''
        for i in $(zfs list -t snapshot "$1" -H | awk '{print $1}' | grep autosnap); do 
            echo WILL DESTROY: "$i"
        done

        # Ask for confirmation
        read -r -p "Are you sure you want to destroy these snapshots? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            for i in $(zfs list -t snapshot "$1" -H | awk '{print $1}' | grep autosnap); do 
                sudo zfs destroy "$i"
            done
        else
            echo "Operation cancelled."
        fi
      '';
    };

    # add bookmarks for gtk
    hm = { ... }@hmCfg: {
      gtk.gtk3.bookmarks = lib.optionals cfg.wdc1tb [
        "file://${wdc-data-mountpoint}/ wdc-blue/data"
        "file://${wdc-okii-mountpoint}/ wdc-blue/okii"
        "file://${wdc-data-mountpoint}/_DOCUMENTS/ _DOCUMENTS"
        "file://${home-dir}/_CURRENT/ _CURRENT"
        "file://${wdc-data-mountpoint}/_SMALL/ _SMALL"
        "file://${wdc-data-mountpoint}/_MAIN/ _MAIN"
        "file://${wdc-data-mountpoint}/_SMALL/ _SMALL"
        "file://${wdc-data-mountpoint}/_MAIN/_NT_STUDIO/ _NT_STUDIO"
        "file://${wdc-data-mountpoint}/_ONLINE_TANK/ _ONLINE_TANK"

        "file://${wdc-okii-mountpoint}/_ANIME/ _ANIME"
        "file://${wdc-okii-mountpoint}/_FILM/ _FILM"
        "file://${wdc-data-mountpoint}/_SMALL/_BOOK/ _BOOK"
        "file://${wdc-data-mountpoint}/_SMALL/_IMAGE/ _IMAGE"
        "file://${wdc-data-mountpoint}/_SMALL/_MUSIC/ _MUSIC"
        "file://${wdc-data-mountpoint}/_SMALL/_GAME/ _GAME"
        "file://${wdc-data-mountpoint}/_SMALL/_H/ _H"
        "file://${wdc-data-mountpoint}/_FARMTASKER/ _FARMTASKER"
        "file://${wdc-data-mountpoint}/_DOCUMENTS/papers/ papers"
      ];
      # create symlinks for locations with ~
      home.file =
        let mkOutOfStoreSymlink = hmCfg.config.lib.file.mkOutOfStoreSymlink;
        in {
          "_MAIN".source = lib.mkIf cfg.wdc1tb
            (mkOutOfStoreSymlink "${wdc-data-mountpoint}/_MAIN");
          "Downloads".source = lib.mkIf cfg.wdc1tb
            (mkOutOfStoreSymlink "${wdc-data-mountpoint}/_DOWNLOADS");
          "Pictures".source = lib.mkIf cfg.wdc1tb
            (mkOutOfStoreSymlink "${wdc-data-mountpoint}/_PICTURES");
          "Videos".source = lib.mkIf cfg.wdc1tb
            (mkOutOfStoreSymlink "${wdc-data-mountpoint}/_VIDEOS");
          "Documents".source = lib.mkIf cfg.wdc1tb
            (mkOutOfStoreSymlink "${wdc-data-mountpoint}/_DOCUMENTS");
          # "Desktop".source = lib.mkIf cfg.wdc1tb
          #   (mkOutOfStoreSymlink "${wdc-data-mountpoint}/_DESKTOP");
          ".config/DecentSampler".source = lib.mkIf config.hm.custom.reaper.enable
            (mkOutOfStoreSymlink "${wdc-okii-mountpoint}/DecentSampler");
        };
    };
 
    # custom.persist = { home.directories = [ "Downloads" "Documents" "Videos" "Desktop" ]; };

    # symlinks from hdds
    # dest src
    systemd.tmpfiles.rules = lib.optionals cfg.enable [
      # "L+ ${wdc-data-mountpoint}/Wallpapers            - - - - /home/${user}/Pictures/Wallpapers"
      # "L+ ${wdc-data-mountpoint}/pr/rustpr             - - - - /home/${user}/pr/rustpr/ln/"
      # "L+ /home/${user}/_MAIN                          - - - - ${wdc-data-mountpoint}/_MAIN"
      # "L+ /home/${user}/_SMALL                         - - - - ${wdc-data-mountpoint}/_SMALL"
      # "L+ /home/${user}/_FARMTASKER                    - - - - ${wdc-data-mountpoint}/_FARMTASKER"
      # "L+ /home/${user}/_SMALL/_MUSIC                  - - - - ${wdc-data-mountpoint}/_MUSIC"
      # "L+ /home/${user}/_SMALL/_FILM                   - - - - ${wdc-data-mountpoint}/_FILM"
      # "L+ /home/${user}/_SMALL/_ANIME                  - - - - ${wdc-data-mountpoint}/_ANIME"
      "L+ /home/${user}/tn                  - - - - ${wdc-data-mountpoint}/_ONLINE_TANK"
    ];

    # dual boot windows
    # use `lsblk -f` to find correct windows boot partition uuid
    boot.loader.grub = {
      extraEntries = lib.concatStringsSep "\n" (
        lib.optional cfg.windows ''
          menuentry "Windows 10" {
            insmod part_gpt
            insmod ntfs
            insmod search_fs_uuid
            insmod chain
            search --fs-uuid --set=root 8CCE-C9D5
            chainloader /EFI/Microsoft/Boot/bootmgfw.efi
          }
        ''
      );
    };

    fileSystems = lib.mkIf cfg.enable {
      # "/md/windows" = lib.mkIf cfg.windows {
      #   device = "/dev/disk/by-label/WINDOWS";
      #   fsType = "ntfs";
      #   neededForBoot = false;
      # };
      "/md/wdc-data" = lib.mkIf cfg.wdc1tb {
        device = "wdc-blue/data";
        fsType = "zfs";
        neededForBoot = false;
      };
      "/md/wdc-okii" = lib.mkIf cfg.wdc1tb {
        device = "wdc-blue/okii";
        fsType = "zfs";
        neededForBoot = false;
      };
    };
  };
}

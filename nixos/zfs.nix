{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.zfs;
  persistCfg = config.custom.persist;
in
# NOTE: zfs datasets are created via install.sh
{
  boot = {
    # booting with zfs
    supportedFilesystems = [ "zfs" ];
    # kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    # kernelPackages = pkgs.linuxPackages_xanmod_latest; # commented out because of musnix owning it now in audio.nix
    kernelParams = [ "zfs.zfs_arc_max=17179869184" ];

    zfs = {
      devNodes = lib.mkDefault "/dev/disk/by-id";
      package = pkgs.zfs_unstable;
      requestEncryptionCredentials = cfg.encryption;
    };
  };

  systemd.services."zfs-import-wdc-blue".serviceConfig.TimeoutStartSec = "30";

  services.zfs = {
    autoScrub.enable = true;
    trim.enable = true;
  };

  # 16GB swap
  # swapDevices = [ { device = "/dev/disk/by-label/SWAP"; } ];

  # standardized filesystem layout
  fileSystems = {
    # boot partition
    "/boot" = {
      device = "/dev/disk/by-label/NIXBOOT";
      fsType = "vfat";
    };

    # zfs datasets
    # "/" = {
    #   device = "zroot/root";
    #   fsType = "zfs";
    #   neededForBoot = !persistCfg.tmpfs;
    # };

    "/nix" = {
      device = "zroot/nix";
      fsType = "zfs";
    };

    "/tmp" = {
      device = "zroot/tmp";
      fsType = "zfs";
    };

    "/persist" = {
      device = "zroot/persist";
      fsType = "zfs";
      neededForBoot = true;
    };

    "/persist/cache" = {
      device = "zroot/cache";
      fsType = "zfs";
      neededForBoot = true;
    };
  };

  systemd.services.systemd-udev-settle.enable = false;

  environment.systemPackages = [
    pkgs.sanoid
    (pkgs.writeShellScriptBin "zfs-rollback" ''
      DATASET=$(zfs list -H -o name | ${pkgs.fzf}/bin/fzf --header="Select dataset")
      [ -z "$DATASET" ] && exit 1
      SNAPSHOT=$(zfs list -t snapshot -r "$DATASET" -o name -H | ${pkgs.fzf}/bin/fzf --header="Select snapshot")
      [ -z "$SNAPSHOT" ] && exit 1
      sudo zfs rollback -r "$SNAPSHOT"
    '')
  ];

  services.sanoid = lib.mkIf cfg.snapshots {
    enable = true;
    interval = "hourly";
    settings = {
      template_backup = {
        frequent_period = 15;

        frequently = 4;
        hourly_min = 0;
        daily_hour = 23;
        daily_min = 59;
      };
    };

    templates.backup = {
        hourly = 24;
        daily = 7;
        weekly = 7;
        monthly = 3;
    };

    datasets = {
      "zroot/persist" = {
        use_template = [ "backup" ];
        hourly = 24;
        daily = 7;
        weekly = 7;
        monthly = 3;
      };
    };
  };
}

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
    kernelParams = [
      "zfs.zfs_arc_max=17179869184"
      # Resilver/scrub throttling - stock defaults let a resilver issue as
      # much I/O as the vdev will take, which starves everything else
      # (confirmed tonight: a resilver alone drove IO pressure to 45%+ full
      # stall). These trade resilver/scrub speed for leaving headroom for
      # latency-sensitive work (audio) while one is running.
      "zfs.zfs_scan_vdev_limit=4194304" # 4MB/vdev per scan interval, down from 16MB default
      "zfs.zfs_vdev_scrub_max_active=1" # down from 3 - less queue depth competing with other IO
      "zfs.zfs_resilver_min_time_ms=500" # down from 1500 - less guaranteed time slice per txg
    ];

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

  # A resilver/reattach cycle can leave a vdev's trim state stale - confirmed
  # firsthand: after this pool's resilver, KISSIN's random-read IOPS had
  # collapsed to ~1300 (vs. a healthy 30-40k+), and a manual `zpool trim`
  # fully recovered it. Don't wait for the weekly autotrim to catch that -
  # trim right when a resilver finishes.
  environment.etc."zfs/zed.d/resilver_finish-trim.sh" = {
    mode = "0555";
    text = ''
      #!${pkgs.runtimeShell}
      [ -f "''${ZED_ZEDLET_DIR}/zed.rc" ] && . "''${ZED_ZEDLET_DIR}/zed.rc"
      . "''${ZED_ZEDLET_DIR}/zed-functions.sh"

      [ -n "''${ZEVENT_POOL}" ] || exit 1
      zed_check_cmd "''${ZPOOL}" || exit 1

      zed_log_msg "Trimming ''${ZEVENT_POOL} after resilver finish"
      "''${ZPOOL}" trim "''${ZEVENT_POOL}"
    '';
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

  # Defense-in-depth for bulk operations (rsync, cp, etc) on top of the
  # realtime-audio.slice weighting in nixos/audio.nix: weight-based
  # fairness only kicks in once there's contention, and already-dispatched
  # low-priority requests can't be preempted mid-flight. A hard bandwidth
  # cap means a bulk job never even tries to saturate the drive in the
  # first place, so there's less queued-up work for anything latency
  # sensitive to wait behind. Low IOWeight here is just belt-and-suspenders
  # on top of that.
  systemd.slices.background-bulk = {
    description = "Bulk/background IO - lowest priority, bandwidth-capped";
    sliceConfig = {
      IOWeight = 10;
    };
  };

  environment.systemPackages = [
    pkgs.sanoid
    (pkgs.writeShellScriptBin "niceio" ''
      set -u
      if [ $# -eq 0 ]; then
        echo "usage: niceio <command> [args...]" >&2
        echo "runs a command bandwidth-capped (20MB/s) on whatever drives currently back zroot" >&2
        exit 1
      fi

      devices=""
      for name in $(zpool status zroot 2>/dev/null | awk '/ONLINE|DEGRADED|OFFLINE/ && !/zroot|mirror|pool:|state:/ {print $1}'); do
        real=$(readlink -f "/dev/disk/by-id/$name" 2>/dev/null) || continue
        devices="$devices $real"
      done

      if [ -z "$devices" ]; then
        echo "niceio: could not resolve zroot member devices, running unthrottled" >&2
        exec "$@"
      fi

      args="--user --scope --slice=background-bulk.slice"
      for d in $devices; do
        args="$args -p IOReadBandwidthMax=$d\ 20M -p IOWriteBandwidthMax=$d\ 20M"
      done

      exec ${pkgs.systemd}/bin/systemd-run $args -- "$@"
    '')
    (pkgs.writeShellScriptBin "zfs-rollback" ''
      DATASET=$(zfs list -H -o name | ${pkgs.fzf}/bin/fzf --header="Select dataset")
      [ -z "$DATASET" ] && exit 1
      SNAPSHOT=$(zfs list -t snapshot -r "$DATASET" -o name -H | ${pkgs.fzf}/bin/fzf --header="Select snapshot")
      [ -z "$SNAPSHOT" ] && exit 1
      sudo zfs rollback -r "$SNAPSHOT"
    '')
    (pkgs.writeShellScriptBin "zfs-rm-snapshot" ''
      while true; do
        SNAPSHOT=$(zfs list -t snapshot -r zroot/persist | awk '{print $1}' | tail -n +2 | ${pkgs.fzf}/bin/fzf --header="Select snapshot to destroy (^C to quit)")
        [ -z "$SNAPSHOT" ] && continue

        read -r -p "Destroy $SNAPSHOT? [y/N] " confirm1
        [ "$confirm1" != "y" ] && [ "$confirm1" != "Y" ] && echo "Cancelled." && continue

        read -r -p "Are you sure? This is irreversible. [y/N] " confirm2
        [ "$confirm2" != "y" ] && [ "$confirm2" != "Y" ] && echo "Cancelled." && continue

        sudo zfs destroy "$SNAPSHOT" && echo "Destroyed $SNAPSHOT."
      done
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
      # Local-only protection (accidental delete, bad update, etc). Not
      # replicated off-pool anywhere - it's all regenerable Steam data, see
      # nixos/steam.nix for why.
      "zroot/steam" = {
        use_template = [ "backup" ];
        hourly = 24;
        daily = 7;
        weekly = 7;
        monthly = 3;
      };
    };
  };
}

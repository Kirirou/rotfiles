{ user, pkgs, ... }:
{
  imports = [ ./minecraft-servers.nix ];
  custom = {
    # hardware
    xkbLayout = "jp";
    hdds = {
      enable = true;
      stsea3tb = false;
      wdc1tb = true;
      windows = true;
    };
    nvidia.enable = true;
    zfs.encryption = false;

    dns.enable = true;
    bluetooth.enable = true;
    vm.enable = true;
    hotspot = {
      enable = true;
      internet_iface = "eno1";
      wifi_iface = "wlp2s0";
    };


    # software
    fileshare.enable = true;
    samba.enable = false;

    monero.enable = true;
    wine.enable = true;
    distrobox.enable = false;
    jellyfin.enable = false;
    pr_managment.enable = true;
    nginx.enable = true;
    llm.enable = true;
    docker.enable = true;
    surrealdb.enable = true;
    bittorrent = {
      enable = true;
      downloadDir = "/home/${user}/_CURRENT";
    };
    flatpak.enable = true;
    steam.enable = true;
    lutris.enable = false;
  };
  
  systemd.user.services.scrcpy = {
    enable = false;
    description = "Start scrcpy when Motorola G54 5G is connected";
    serviceConfig = {
      ExecStart = "${pkgs.scrcpy}/bin/scrcpy --video-bit-rate=24M --max-size=2560";
      Restart = "on-failure";
      Environment = "DISPLAY=:0";
    };
    wantedBy = [ "default.target" ];
  };
  services.udev.enable = true;
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="22b8", ATTR{idProduct}=="2e81", TAG+="systemd", ENV{SYSTEMD_USER_WANTS}+="scrcpy.service"

    # Disable SATA link power management (med_power_with_dipm) on the ZFS/backup
    # disks: it lets the link drop into a low-power state between commands, and
    # a burst flush (eg. sanoid's hourly ZFS snapshots) can hit a disk mid-wakeup
    # and get aborted, triggering an ATA EH reset that stalls I/O system-wide for
    # a moment. Desktop is always on mains, so there's no benefit to link PM here.
    ACTION=="add", SUBSYSTEM=="scsi_host", KERNEL=="host*", ATTR{link_power_management_policy}="max_performance"

    # hwmonN numbering isn't stable across boots (depends on kernel module
    # probe order) - after one reboot hwmon2 was coretemp, after another it
    # was iwlwifi's thermal sensor instead, silently making waybar display
    # the wifi card's temperature labeled as CPU temp. Create a boot-stable
    # symlink to whichever hwmon is actually named "coretemp" and point
    # waybar's hwmon-path at that instead of a hardcoded index.
    SUBSYSTEM=="hwmon", ATTR{name}=="coretemp", RUN+="${pkgs.coreutils}/bin/ln -sf /sys%p/temp1_input /run/coretemp-temp1_input"
  '';

    users.users.${user} = {...}: {
      extraGroups = [ "plugdev" ];
    };

  services.displayManager.autoLogin.user = user;

  networking.hostId = "83efa833"; # required for zfs

  networking.firewall.allowedTCPPorts = [ 4444 7777 77 ];
  networking.firewall.allowedUDPPorts = [ 4444 7777 77 ];

  # networking.firewall.enable = false;

  # fix clock to be compatible with windows
  time.hardwareClockInLocalTime = true;
}

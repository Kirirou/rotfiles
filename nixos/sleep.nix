{
  lib,
  user,
  ...
}: {
  # boot.resumeDevice = "/dev/disk/by-label/SWAP";
  boot.kernelParams = ["mem_sleep_default=deep"];

  boot.zfs.allowHibernation = true;
  boot.zfs.forceImportRoot = false;

  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    "hybrid-sleep".enable = false;
  };
  services.acpid = {
    enable = true;
    lidEventCommands = ''
      /etc/profiles/per-user/${user}/bin/hypr-lock
    '';

    powerEventCommands = ''
      /etc/profiles/per-user/${user}/bin/hypr-lock
    '';
  };
}

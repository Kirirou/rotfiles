{
  pkgs,
  lib,
  config,
  ...
}:
lib.mkIf config.custom.lutris.enable {
  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace data/scripts/waydroid-net.sh \
          --replace "iptables" "iptables-nft"
      '';
    });
  };
  networking.networkmanager.unmanaged = [ "interface-name:waydroid0" ];
  environment.systemPackages = with pkgs; [
    (lutris.override {
      extraPkgs = _pkgs: [
        # List package dependencies here
      ];
      extraLibraries = _pkgs: [
        # List library dependencies here
        libadwaita
      ];
    })
  ];
  custom.persist = {
    root.directories = [ "/var/lib/waydroid" ];
    home.directories = [
      ".local/share/lutris"
      ".local/share/waydroid"
      "Games"
    ];
  };
}

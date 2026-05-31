{
  config,
  user,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.static-web-server;
  domain-name = "rotteegher.ddns.net";
  domain-name2 = "local.farmtasker.au";
  path-to-serve = "/md/wdc-data/_SMALL/_ONLINE_TANK";
in lib.mkMerge [
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "souonchouryuu@proton.me";
  };

  # Now we need to open port 80 for the ACME challenge and port 443 for SWS itself
  networking.firewall.allowedTCPPorts = [ 80 443 3210 3211 ];
  networking.firewall.allowedUDPPorts = [ 80 443 3210 3211 ];

  environment.systemPackages = [ pkgs.copyparty ];

  services.onedrive.enable = true;

  custom.persist = {
    root.directories = ["/var/lib/acme" "/var/lib/filebrowser"];
  };
}
]

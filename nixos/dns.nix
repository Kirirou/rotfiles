{config, lib, pkgs, ...}: 
lib.mkIf config.custom.dns.enable {
  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  services.bind = {
    enable = true;
    ipv4Only = true;
    listenOn = [ "127.0.0.1" "192.168.1.101" ];
    zones = {
      "farmtasker.au" = {
        master = true;
        file = pkgs.writeText "zone-farmtasker.au" ''
          $ORIGIN farmtasker.au.
          $TTL 2d
          @            IN      SOA     ns1.farmtasker.au. admin.farmtasker.au. (
                                 1    ; Serial
                                 3h   ; Refresh
                                 1h   ; Retry
                                 1w   ; Expire
                                 1h)  ; Negative Cache TTL
                       IN      NS      ns1
                       IN      NS      ns2
          @            IN      A       93.127.166.200
          coolify      IN      A       93.127.166.200
          pr           IN      A       192.168.1.101
          local        IN      A       192.168.1.101
          jellyfin     IN      A       192.168.1.101
          nextcloud    IN      A       192.168.1.101
          ns1          IN      A       192.168.1.101
          ns2          IN      A       192.168.1.101
        '';
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}

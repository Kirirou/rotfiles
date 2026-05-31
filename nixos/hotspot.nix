{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.hotspot;
in {
  config = lib.mkIf (config.hm.custom.wifi.enable && cfg.enable) {

    # Remove create_ap entirely
    # services.create_ap = { ... };  # delete this

    # Bridge: eno1 + hostapd will add the wifi side
    networking.bridges.br0.interfaces = [ "eno1" ];

    networking.interfaces.br0 = {
      ipv4.addresses = [{
        address = "192.168.1.101";
        prefixLength = 24;
      }];
    };

    # eno1 should not have its own IP anymore
    networking.interfaces.eno1.ipv4.addresses = lib.mkForce [];

    networking.defaultGateway = "192.168.1.1";
    networking.nameservers = [ "192.168.1.1" ];

    networking.networkmanager.unmanaged = [ cfg.wifi_iface ];
    networking.wireless.interfaces = lib.mkForce [];

    services.hostapd = {
      enable = true;
      radios.${cfg.wifi_iface} = {
        band = "2g";       # or "5g" if your card and router both support it
        channel = 6;        # must differ from your TP-Link's channel
        networks.${cfg.wifi_iface} = {
          ssid = cfg.ssid;  # set this to your TP-Link's exact SSID
          authentication = {
            mode = "wpa2-sha1";
            # saePasswords = [{ password = cfg.passphrase; }];
            wpaPassword = cfg.passphrase;  # exact same password as TP-Link
          };
          settings = {
            bridge = "br0";
            # wpa = lib.mkForce 3;          # 1=WPA, 2=WPA2, 3=both (mixed mode)
            # wpa_pairwise = lib.mkForce "TKIP CCMP";
          };
        };
      };
    };
  };
}

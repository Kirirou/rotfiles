{ lib, isLaptop, ... }:
{
  options.custom = {
    xkbLayout = lib.mkOption {
      type = lib.types.str;
      default = "us";
    };
    nvidia.enable = lib.mkEnableOption "Nvidia GPU";
    bluetooth.enable = lib.mkEnableOption "Bluetooth" // {
      default = isLaptop;
    };

    dns.enable = lib.mkEnableOption "Domain Name Server" // {
      default = false;
    };
    vm.enable = lib.mkEnableOption "vm" // {
      default = false;
    };

    hotspot = {
      enable = lib.mkEnableOption "WiFI Broadcast HotSpot" // {
        default = false;
      };
      internet_iface = lib.mkOption {
        type = lib.types.str;
        default = "eno1";
        description = "Interface to get connection from";
      };
      wifi_iface = lib.mkOption {
        type = lib.types.str;
        default = "wlp2s0";
        description = "Interface to broadcast WiFi hotspot from";
      };
      ssid = lib.mkOption {
        type = lib.types.str;
        default = "Farmtasker";
        description = "Hotspot name";
      };
      passphrase = lib.mkOption {
        type = lib.types.str;
        default = "6795CA70";
        description = "Hotspot password";
      };
    };

    samba.enable = lib.mkEnableOption "Samba" // {
      default = false;
    };

    fileshare.enable = lib.mkEnableOption "File Share" // {
      default = false;
    };
    
    hdds = {
      enable = lib.mkEnableOption "Desktop HDDs" // {
        default = false;
      };
      stsea3tb = lib.mkEnableOption "stsea-barra" // {
        default = false;
      }; # Seagate Barracuda 3TB ST3000DM007
      wdc1tb = lib.mkEnableOption "wdc-blue" // {
        default = false;
      }; # WDC Blue 1TB WD10SPZX
      windows = lib.mkEnableOption "Windows" // {
        default = false;
      };
    };

    zfs = {
      encryption = lib.mkEnableOption "zfs encryption" // {
        default = true;
      };
      snapshots = lib.mkEnableOption "zfs snapshots" // {
        default = true;
      };
    };
  };
}

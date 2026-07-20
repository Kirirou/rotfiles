{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    protonvpn-gui
    proton-vpn-cli
  ];


}

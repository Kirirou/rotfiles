{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}:
lib.mkIf config.custom.hyprland.enable {
  services.desktopManager.gnome.enable = lib.mkForce false;
  services.xserver.displayManager.lightdm.enable = lib.mkForce false;
  # services.displayManager.ly.enable = lib.mkForce true;

  # Hyprland is started manually (the "hy" alias -> start-hyprland), often
  # from an SSH session rather than the physical console. logind's default
  # seat backend only grants GPU/input device access to sessions it
  # classifies as an actual seat0 console login, so an SSH-launched Hyprland
  # gets "libseat: Operation not permitted" on every input device and then
  # "drm: Found no gpus to use" -> CBackend::create() failed, regardless of
  # user permissions. seatd hands out device access itself, independent of
  # session origin, which is what this workflow actually needs.
  services.seatd.enable = true;
  users.users.${user}.extraGroups = [ "seat" ];

  # See https://nixos.org/manual/nixos/stable/release-notes#sec-release-23.11
  # Fcitx5 Doesn't Start When Using WM
  # As of NixOS 23.11 i18n.inputMethod.enabled no longer creates systemd services for fcitx5.
  # Instead it relies on XDG autostart files. If using a Window Manager (WM), such as Sway, you may need to add vvvTHISvvv to your NixOS configuration. 
  services.xserver.desktopManager.runXdgAutostartIfNone = true;

  programs.hyprland =
    {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };

  # set here as legacy linux won't be able to set these
  hm.wayland.windowManager.hyprland.enable = true;

  # lock hyprland to 0.38.1 until workspace switching is resolved
  nixpkgs.overlays = [ (_: _prev: { inherit (inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}) hyprland; }) ];

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}

{
  config,
  inputs,
  lib,
  pkgs,
  user,
  ...
}:
{
  imports = [ inputs.mango.nixosModules.mango ];

  options.custom.mango.enable = lib.mkEnableOption "the Mango Wayland compositor";

  config = lib.mkIf config.custom.mango.enable {
    # Same reasoning as hyprland.nix: Mango (like Hyprland) is started manually
    # from a shell, often over SSH rather than a physical console login, so
    # logind's normal seat-granting path doesn't apply. seatd hands out
    # GPU/input device access directly regardless of how the session was
    # started. Harmless to enable again if hyprland.nix already did - NixOS
    # just merges the same `true` value.
    services.seatd.enable = true;
    users.users.${user}.extraGroups = [ "seat" ];

    services.xserver.desktopManager.runXdgAutostartIfNone = true;

    programs.mango = {
      enable = true;
      # Not using the display-manager login entry - mirrors how Hyprland is
      # launched here (manual alias from a shell), not through a DM/greetd.
      addLoginEntry = false;
    };

    hm.wayland.windowManager.mango.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
  };
}

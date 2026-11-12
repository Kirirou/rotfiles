{ config, pkgs, lib, ... }:
let
  cfg = config.custom.xmrig;
in
{
  config = lib.mkIf cfg.enable {
    # `xm` controls the systemd services defined in nixos/xmrig.nix (it
    # doesn't spin up its own xmrig process) - starts the right unit for
    # the requested backend(s), streams its journal to the terminal, and
    # stops the unit again on Ctrl+C (or any other exit) via the EXIT trap.
    # Plain (non --user) systemctl/journalctl throughout: these are
    # system-level units now (needed for AmbientCapabilities, see
    # nixos/xmrig.nix), made password-free via the scoped polkit rule
    # there rather than sudo.
    home.packages = [
      (pkgs.writeShellApplication {
        name = "xm";
        runtimeInputs = [ pkgs.systemd ];
        text = ''
          if [ "''${1-}" = s ]; then
            # Stop whichever variant happens to be running - only one of
            # the three is ever active at a time, and stopping an already
            # inactive unit is a harmless no-op.
            systemctl stop xmrig xmrig-cpu xmrig-gpu
            exit 0
          fi

          if [ "''${1-}" = w ]; then
            # Attach to whichever variant is currently running, without
            # starting or stopping anything - for reattaching to a session
            # started elsewhere (eg. left mining overnight). Ctrl+C just
            # detaches here, it does not stop the service.
            for u in xmrig xmrig-cpu xmrig-gpu; do
              if systemctl is-active --quiet "$u"; then
                exec journalctl -u "$u" -f
              fi
            done
            echo "xm: no xmrig service is currently running" >&2
            exit 1
          fi

          case "''${1-}" in
            "" | -cg | -gc) unit=xmrig ;;
            -c) unit=xmrig-cpu ;;
            -g) unit=xmrig-gpu ;;
            *)
              echo "Usage: xm [-c|-g|-cg|-gc|s|w]" >&2
              exit 1
              ;;
          esac

          trap 'systemctl stop "$unit" >/dev/null 2>&1 || true' EXIT

          systemctl start "$unit"
          journalctl -u "$unit" -f --since now
        '';
      })
    ];
  };
}

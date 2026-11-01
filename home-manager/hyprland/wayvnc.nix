{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.wayvnc;
  displays = config.custom.displays;
  primaryOutput = (lib.head displays).display_name_output;
  headlessName = "HEADLESS-1";
  jq = lib.getExe pkgs.jq;
  # Pulled out into a real script rather than an inline one-liner inside the
  # Lua extraConfig string - that version needed shell quoting nested inside
  # a jq program nested inside a Lua string, four layers deep, and a mis-
  # escaped quote in it would silently truncate the Lua string early. Much
  # easier to get right (and to verify) as an actual file.
  createHeadlessMirror = pkgs.writeShellScript "create-headless-mirror" ''
    hyprctl output create headless
    sleep 1
    mode=$(hyprctl monitors -j | ${jq} -r '.[] | select(.name=="${primaryOutput}") | "\(.width)x\(.height)@\(.refreshRate)"')
    hyprctl keyword monitor "${headlessName},$mode,auto,1,mirror,${primaryOutput}"
  '';
in
lib.mkIf cfg.enable {
  # wayvnc dies outright whenever the real output goes to sleep/disconnects
  # (not just DPMS-off, which it handles fine - the output actually going
  # away entirely). Give it a headless virtual output that mirrors the real
  # one to capture instead, so it's decoupled from the physical monitor's
  # power state entirely and never has "no outputs left" to fall over on.
  #
  # The mirror's mode is pinned to the primary output's exact mode rather
  # than left as "preferred" - a headless/virtual output's "preferred" mode
  # commonly negotiates a generic 60Hz, which then runs as a differently
  # clocked render target alongside the real ~144Hz output in the same
  # compositor loop.
  #
  # This used to just embed displays' static `mode` string (e.g.
  # "5120x1440@144") directly. Confirmed broken live once that field became
  # the "highres" keyword (home-manager/hyprland/default.nix fix for this
  # monitor's unreliable EDID preferred-timing flag) - a keyword means
  # nothing to a virtual output with no EDID to resolve it against, so the
  # mirror command silently failed (`mirrorOf: none` in `hyprctl monitors`)
  # and HEADLESS-1 started behaving as an independent output, stealing
  # workspaces instead of mirroring DP-3. Resolving the primary output's
  # ACTUAL current mode at runtime via `hyprctl monitors -j` instead, so
  # this keeps working regardless of whether `mode` in the Nix config is a
  # literal string or a keyword, and regardless of which physical PBP state
  # (5120x1440 whole vs 2560x1440 split) the monitor is actually in when
  # Hyprland starts.
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("${createHeadlessMirror}")
    end)
  '';

  systemd.user.services.wayvnc = {
    Unit = {
      Description = "wayvnc remote desktop server";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.wayvnc} --render-cursor --output=${headlessName} 127.0.0.1 ::1";
      Restart = "always";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}

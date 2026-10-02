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
  primaryMode = (lib.head displays).mode;
  headlessName = "HEADLESS-1";
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
  wayland.windowManager.hyprland.extraConfig = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("hyprctl output create headless")
      hl.exec_cmd("sleep 1 && hyprctl keyword monitor '${headlessName},${primaryMode},auto,1,mirror,${primaryOutput}'")
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

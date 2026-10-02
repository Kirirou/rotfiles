{ config, lib, pkgs, ... }:
let
  wlrRandr = lib.getExe pkgs.wlr-randr;
  monitorsWithWlrMode = lib.filter (d: d.wlr_mode != null) config.custom.displays;
  monitorReapply = lib.optionalString (monitorsWithWlrMode != []) (
    lib.concatMapStringsSep " && "
      ({ display_name_output, wlr_mode, ... }:
        "${wlrRandr} --output ${display_name_output} --mode ${wlr_mode}"
      )
      monitorsWithWlrMode
  );
in
{
  services.hypridle = {
    enable = true;

    settings =
      let
        timeout = 5 * 60;
      in
      lib.mkMerge [
        {
          general = {
            ignore_dbus_inhibit = false;
          };

          listener = [
            {
              inherit timeout;
              on-timeout = "hyprctl eval 'hl.dispatch(hl.dsp.dpms(\"off\"))'";
              on-resume = "hyprctl eval 'hl.dispatch(hl.dsp.dpms(\"on\"))'${lib.optionalString (monitorReapply != "") " && sleep 1 && ${monitorReapply}"}";
            }
          ];
        }
        # lock screen on idle
        (lib.mkIf config.custom.hyprland.lock {
          general = {
            lock_cmd = "hyprlock";
          };

          listener = [
            {
              inherit timeout;
              on-timeout = "hyprlock";
            }
          ];
        })
      ];
  };
}

{ config, lib, inputs, pkgs, ... }:
let
  pamixer = lib.getExe pkgs.pamixer;
in
{
  imports = [ inputs.mango.hmModules.mango ];

  config = lib.mkIf config.wayland.windowManager.mango.enable {
    wayland.windowManager.mango = {
      settings = {
        blur = 1;
        border_radius = 6;
        bordercolor = "0x595959aa";
        focused_opacity = 1.0;
        animations = 1;
        animation_duration_open = 300;
        animation_duration_close = 200;

        layout = "scroller";

        bind = [
          "SUPER,r,reload_config"
          "SUPER CTRL,r,quit" # Hyprland: SUPER+CTRL+5 exit. No separate "restart" dispatcher found in docs - quit and relaunch via the mg/mango alias.

          # --- exec (direct 1:1, kept kitty/rofi/nemo as-is) ---
          "SUPER,Return,spawn,kitty"
          "SUPER SHIFT,Return,spawn,rofi -show drun"
          "SUPER,b,spawn,nemo ~/Downloads"
          # power-menu font arg dropped - config.custom.fonts.monospace isn't readable from this
          # module the way it is in hyprland/keybinds.nix; add back once confirmed available here.
          "SUPER CTRL,Return,spawn,rofi -show power-menu -modi power-menu:rofi-power-menu"

          # --- kill ---
          "SUPER,BackSpace,killclient"
          "SUPER,Escape,killclient"
          # Hyprland also had SUPER+CTRL+BackSpace -> hyprctl kill (force-kill, bypasses the
          # app's own close handler). No separate "force kill" dispatcher turned up in the docs
          # I could pull - killclient is likely the only kill action. Worth checking `mango -h`
          # or the live docs once it's running; dropped for now rather than guessing wrong.

          # --- focus (direction-based, confirmed dispatcher: focusdir) ---
          "SUPER,h,focusdir,left"
          "SUPER,l,focusdir,right"
          "SUPER,k,focusdir,up"
          "SUPER,j,focusdir,down"

          # --- move window (direction-based) ---
          # UNVERIFIED exact arg syntax - the docs fetch confirmed "movewin"/"smartmovewin" exist
          # but not their exact argument format. Guessing the same pattern as the confirmed
          # resizewin (pixel delta, x y) below, consistent with the one worked example the nix
          # wiki page actually showed. Test this specifically before relying on it.
          "SUPER SHIFT,h,movewin,-20,0"
          "SUPER SHIFT,l,movewin,20,0"
          "SUPER SHIFT,k,movewin,0,-20"
          "SUPER SHIFT,j,movewin,0,20"

          # --- tags (see note below on the 9-tag vs 13-workspace mismatch) ---
          # Primary 1-9 mapped directly. The secondary keyboard-row letters your Hyprland config
          # also binds to workspaces 5-13 (q/w/e/a/s/d/z/x/c) are NOT mapped here yet - Mango's
          # tag system is dwm-derived and conventionally caps at 9 tags, so the full 13-way split
          # across two monitors needs to be worked out live (does mango support >9 tags? does it
          # have a Hyprland-style "pin this workspace range to that monitor" feature via
          # focusmon/tagmon?) rather than guessed here. Treat 1-9 as the safe starting point.
          "SUPER,1,view,1"
          "SUPER,2,view,2"
          "SUPER,3,view,3"
          "SUPER,4,view,4"
          "SUPER,5,view,5"
          "SUPER,6,view,6"
          "SUPER,7,view,7"
          "SUPER,8,view,8"
          "SUPER,9,view,9"
          "SUPER SHIFT,1,tag,1"
          "SUPER SHIFT,2,tag,2"
          "SUPER SHIFT,3,tag,3"
          "SUPER SHIFT,4,tag,4"
          "SUPER SHIFT,5,tag,5"
          "SUPER SHIFT,6,tag,6"
          "SUPER SHIFT,7,tag,7"
          "SUPER SHIFT,8,tag,8"
          "SUPER SHIFT,9,tag,9"

          # --- monitor focus/send (Hyprland: SUPER+CTRL+h/l focus monitor, +j/k send window) ---
          # focusmon/tagmon confirmed to exist as dispatchers; exact monitor-identifier argument
          # (output name like "DP-3", or an index/direction) not confirmed from docs - same
          # caveat as movewin above, test live.
          "SUPER CTRL,l,focusmon,DP-3"
          "SUPER CTRL,h,focusmon,DP-2"
          "SUPER CTRL,k,tagmon,DP-2"
          "SUPER CTRL,j,tagmon,DP-3"

          # --- fullscreen / floating ---
          "SUPER,f,togglefullscreen" # Hyprland SUPER+n (maximized) and SUPER+f (fullscreen) both
          "SUPER,n,centerwin" # repurposed - Mango doesn't appear to distinguish maximize vs
          # fullscreen as two separate states the way Hyprland's fullscreen_state internal/client
          # split does; togglefullscreen is the closest single equivalent. centerwin is a
          # different, genuinely new action (centers a floating window) - put on the freed SUPER+n.
          "SUPER,g,togglefloating" # was SUPER+g in Hyprland too, kept as-is
          "SUPER,m,toggleglobal" # best guess for Hyprland's SUPER+CTRL+s window-pin ("sticky,
          # show on all workspaces") - toggleglobal sounds closest in the dispatcher list but
          # wasn't confirmed to be semantically identical, verify once running

          # --- cycle windows (Hyprland: ALT+Tab / ALT+SHIFT+Tab via cycle_next) ---
          "ALT,Tab,focusstack,next"
          "ALT SHIFT,Tab,focusstack,prev"

          # --- layout (Hyprland: SUPER+m addmaster, SUPER+SHIFT+m removemaster, SUPER+r cycle) ---
          "SUPER,equal,incnmaster,1" # closest equivalents using confirmed dispatchers -
          "SUPER,minus,incnmaster,-1" # incnmaster for master-count instead of Hyprland's
          # addmaster/removemaster (different mental model: Hyprland adds/removes specific master
          # slots, Mango's incnmaster increments a count - similar end result, not identical).
          # SUPER+r was reassigned above to reload_config (a direct, more universal binding) since
          # Mango's layout-cycling equivalent of Hyprland's "orientationcycle" wasn't confirmed to
          # exist as a single dispatcher - use setlayout directly instead, bound separately below.
          "SUPER ALT,s,setlayout,scroller"
          "SUPER ALT,d,setlayout,dwindle"
          "SUPER ALT,space,setlayout,monocle"

          # --- audio (unrelated to the compositor, same commands work regardless) ---
          "none,XF86AudioLowerVolume,spawn,${pamixer} -d 5"
          "none,XF86AudioRaiseVolume,spawn,${pamixer} -i 5"
          "none,XF86AudioMute,spawn,${pamixer} -t"
        ] ++ lib.optionals config.custom.backlight.enable [
          "none,XF86MonBrightnessDown,spawn,${lib.getExe pkgs.brightnessctl} set 5%-"
          "none,XF86MonBrightnessUp,spawn,${lib.getExe pkgs.brightnessctl} set +5%"
        ] ++ [
          "SUPER,e,setkeymode,resize"
          "SUPER,space,spawn,fuzzel" # launcher alternative to rofi - remove if you'd rather
          # just use SUPER+SHIFT+Return (rofi) for everything and not install fuzzel at all
        ];

        key_mode.resize.bind = [
          "NONE,Left,resizewin,-20,0"
          "NONE,Right,resizewin,20,0"
          "NONE,Up,resizewin,0,-20"
          "NONE,Down,resizewin,0,20"
          "NONE,Escape,setkeymode,default"
          "NONE,Return,setkeymode,default"
        ];
      };

      autostart_sh = ''
        ironbar &
      '';

      systemd = {
        enable = true;
        variables = [
          "DISPLAY"
          "WAYLAND_DISPLAY"
          "XDG_CURRENT_DESKTOP"
          "XDG_SESSION_TYPE"
          "NIXOS_OZONE_WL"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
        ];
      };
    };

    home.packages = [ pkgs.ironbar ];

    # Functional-priority ironbar config: dense sys_info line (cpu/mem/disk/
    # network/uptime all at once) instead of separate pretty widgets, plus
    # tray and volume. No workspaces module - ironbar's workspaces module
    # explicitly only supports Sway, Hyprland, and Niri (confirmed from its
    # own docs), Mango isn't in that list, so it wouldn't actually work. If
    # ironbar adds Mango support later, or Mango grows a generic
    # wlr-foreign-toplevel-based workspace protocol ironbar can read, this is
    # the place to add it back.
    xdg.configFile."ironbar/config.yaml".text = ''
      position: "top"
      height: 32
      start:
        - type: "sys_info"
          format:
            - " {cpu_percent}% @ {cpu_frequency}GHz"
            - " {memory_used}/{memory_total}GB ({memory_percent}%)"
            - "󰋊 {disk_used#T@/:.1}/{disk_total#T@/:.1}TB ({disk_percent@/}%)"
            - "󰓢 {net_down@eno1}/{net_up@eno1}Mbps"
            - "󰥔 {uptime}"
          interval:
            cpu: 2
            memory: 5
            disks: 60
            networks: 3
      center:
        - type: "clock"
          format: "%Y-%m-%d %H:%M:%S"
      end:
        - type: "volume"
          format: "{icon} {percentage}%"
          icons:
            volume: "󰕾"
            muted: "󰝟"
        - type: "tray"
          direction: "horizontal"
          icon_size: 16
    '';
  };
}

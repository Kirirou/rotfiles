{ config, lib, inputs, pkgs, ... }:
let
  pamixer = lib.getExe pkgs.pamixer;
  gammastep = lib.getExe pkgs.gammastep;

  # ironbar's native "clock" module has no click-to-change-format option (confirmed from its
  # docs - only format/format_popup/locale/show_week_numbers/orientation/justify), so
  # "click to show ISO date" has to be built as a "custom" button+label instead of the native
  # module. That trades away the native module's default click-opens-calendar-popup behavior
  # entirely - nothing else here replaces it. Shared state file so clicking either clock
  # (start's detailed one or end's short one) toggles both in sync. LC_TIME=en_US.UTF-8 is set
  # directly on the date calls (not a locale popup, since there's no popup here) to get English
  # weekday/month names regardless of the system locale, per the "calendar should use en_US" ask.
  ironbarClockToggle = pkgs.writeShellScript "ironbar-clock-toggle" ''
    f="''${XDG_RUNTIME_DIR:-/tmp}/ironbar-clock-iso"
    if [ -e "$f" ]; then rm -f "$f"; else touch "$f"; fi
  '';
  ironbarClockLabel = format: pkgs.writeShellScript "ironbar-clock-label" ''
    f="''${XDG_RUNTIME_DIR:-/tmp}/ironbar-clock-iso"
    if [ -e "$f" ]; then
      LC_TIME=en_US.UTF-8 date -Iseconds | sed 's/T/ /' # ISO date/time, space instead of
      # "T" separating the date from where the hours start
    else
      LC_TIME=en_US.UTF-8 date '+${format}'
    fi
  '';
in
{
  imports = [ inputs.mango.hmModules.mango ];

  config = lib.mkIf config.wayland.windowManager.mango.enable {
    wayland.windowManager.mango = {
      settings = {
        # All eye candy and animations off, matching the Hyprland side of this repo
        # (home-manager/hyprland/default.nix already sets animations.enabled=false,
        # decoration.blur.enabled=false, decoration.rounding=0).
        blur = 0;
        shadows = 0;
        border_radius = 0;
        focused_opacity = 1.0;
        unfocused_opacity = 1.0;
        animations = 0;
        border_px = 3; # matches Hyprland's border_size = 3 (home-manager/hyprland/default.nix)
        # border_color (inactive) / focus_color (active) copied from Hyprland's own compiled-in
        # defaults, since this repo's Hyprland config never overrides them (no col.active_border
        # / col.inactive_border anywhere in home-manager/hyprland/*.nix - confirmed via grep):
        # Hyprland's stock default is col.inactive_border = rgba(595959aa) and
        # col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg (a two-stop gradient). Mango's
        # border_color/focus_color are flat single colors only (confirmed from
        # DreamMaoMao/mango-config's config.conf - no gradient syntax), so focus_color just takes
        # the first gradient stop (33ccffee) rather than trying to fake a gradient.
        border_color = "0x595959aa"; # was "bordercolor" (no underscore) - rejected by the real
        # parser at build time: "Unknown keyword: bordercolor". Confirmed correct name
        # ("border_color") against DreamMaoMao/mango-config, the upstream maintainer's own
        # real-world config repo, not just the docs-site examples.
        focus_color = "0x33ccffee";

        # fcitx running is unrelated to this - fcitx is an input-method framework (handles
        # Japanese text conversion/candidates), it doesn't touch the raw key-to-character
        # map. That's XKB's job, and Mango had no XKB layout override at all (defaulted to
        # whatever the system/base layout is, i.e. ANSI). Hyprland gets this from the same
        # config.custom.kbLayout option (home-manager/hyprland/default.nix: "kb_layout =
        # config.custom.kbLayout"; set to "jp" in hosts/desktop/home.nix) - reusing it here
        # so both compositors follow the same source of truth instead of drifting.
        xkb_rules_layout = config.custom.kbLayout;

        # No top-level "default layout" keyword exists - also rejected at build time ("Unknown
        # keyword: layout") and not present anywhere in the upstream example config either.
        # Mango just starts on its own built-in default; switch via the setlayout binds below.

        # Tags are NOT capped at 9 - confirmed from mangowc source
        # (include/mango/config/preset.h: "tag_num_MAX 31"; common/server.h:
        # "tagmask ... updated with config.tag_num"). Set to 13 to exactly match
        # the old Hyprland 13-workspace layout (1-9, 0=10, z=11, x=12, c=13).
        tag_num = 13;

        # Without this, focusdir (SUPER+hjkl) silently does nothing at a monitor's edge
        # instead of crossing to the next monitor - confirmed from src/dispatch/bind.c's
        # focus_direction(): it only calls focus_monitor() as a fallback when no client is
        # found in that direction AND config.focus_cross_monitor is set. Left
        # focus_cross_tag unset/0 since that's checked FIRST and would shift to an adjacent
        # tag instead of crossing monitors if enabled - not what was asked for.
        focus_cross_monitor = 1;

        # Remove gaps between tiled windows AND between windows and the screen edge.
        gap_inner_horizontal = 0;
        gap_inner_vertical = 0;
        gap_outer_horizontal = 0;
        gap_outer_vertical = 0;

        # Monitor config, equivalent of config.custom.displays for Hyprland. The DP-3
        # ultrawide is one physical panel that's either a single 5120x1440@144 output
        # (PBP off, HDMI unplugged), or splits into two half-width inputs - DP-3 at
        # 2560x1440 and HDMI-A-1 (2560x1440@60) - when PBP/PIP 1:1 split is on. Deliberately
        # NOT specifying width/height/refresh here: ConfigMonitorRule's fields are plain
        # int32_t with no "unset" sentinel visible in the struct (include/mango/config/
        # parse.h), but the APPLY_INT_PROP pattern used elsewhere in this codebase
        # (`if (rule->prop >= 0) obj->prop = rule->prop`) strongly implies omitted/negative
        # fields fall through to whatever the output currently negotiates - which is exactly
        # "dynamic": DP-3 comes up at 5120x1440@144 when alone, or 2560x1440 when split,
        # with no config change needed either way. UNCONFIRMED live - if DP-3 or HDMI-A-1
        # comes up at some bogus/fallback resolution instead, that inference was wrong and
        # these need explicit width/height/refresh per Hyprland's displays list
        # (hosts/desktop/home.nix) instead.
        monitor_rule = [
          "name:DP-3,x:0,y:0,scale:1,vrr:0,rr:0"
          "name:HDMI-A-1,x:2560,y:0,scale:1,vrr:0,rr:0"
          # DP-2 is a separate, third monitor (not part of the DP-3/HDMI-A-1 split) - kept
          # fixed since Hyprland's own config does the same ("retired from the workspace
          # scheme... still positioned/configured for whenever it's actually connected").
          "name:DP-2,width:2560,height:1080,refresh:200,x:2560,y:1440,scale:1,vrr:0,rr:0"
        ];

        bind = [
          "SUPER,r,reload_config"
          "SUPER+CTRL,r,quit" # Hyprland: SUPER+CTRL+5 exit. No separate "restart" dispatcher found in docs - quit and relaunch via the mg/mango alias.

          # --- exec (direct 1:1, kept kitty/rofi/nemo as-is) ---
          "SUPER,Return,spawn,kitty"
          "SUPER+SHIFT,Return,spawn,rofi -show drun"
          "SUPER,b,spawn,nemo ~/Downloads"
          # power-menu font arg dropped - config.custom.fonts.monospace isn't readable from this
          # module the way it is in hyprland/keybinds.nix; add back once confirmed available here.
          "SUPER+CTRL,Return,spawn,rofi -show power-menu -modi power-menu:rofi-power-menu"

          # --- kill ---
          "SUPER,BackSpace,killclient"
          "SUPER,Escape,killclient"
          # killclient DOES take a force/unforce argument after all (confirmed from
          # src/config/value_parse.c's parse_force()) - matches Hyprland's
          # SUPER+CTRL+BackSpace -> hyprctl kill (force-kill, bypasses the app's own close
          # handler).
          "SUPER+CTRL,BackSpace,killclient,force"

          # --- notifications (dunst is a plain systemd user service - services.dunst.enable
          # in home-manager/programs/dunst.nix, not gated behind Hyprland at all - so it's
          # already running under Mango too, just needed the bind) ---
          "SUPER,grave,spawn,dunstctl history-pop"

          # --- warm color temperature overlay (replaces Hyprland's hyprshade - a compositor
          # SHADER, which is what was glitching) ---
          # gammastep uses the wlr-gamma-control-v1 protocol, a real compositor-level gamma
          # ramp, not a render shader - confirmed Mango implements it natively
          # (src/main.c: wlr_gamma_control_manager_v1_create()). BUT confirmed live (tested
          # `gammastep -O 4500 -P` directly - it never exited on its own, had to be killed)
          # that "-O" ("one shot") does NOT mean fire-and-forget: the gamma ramp is owned by
          # whichever client holds the wlr-gamma-control connection, and the protocol resets
          # it to neutral the moment that client disconnects. gammastep has to stay resident
          # to keep the effect applied. My first version spawned a new instance per press
          # with nothing killing the previous one - that's what broke everything after one
          # press: two gammastep processes fighting over the same gamma resource. Fixed by
          # managing it as a singleton - pkill the old one before starting a new one; "off"
          # just kills it and lets the protocol's own disconnect-resets-ramp behavior handle
          # the rest. wordexp (what spawn uses, src/dispatch/bind.c) doesn't support `;` or
          # shell chaining on its own, hence the explicit `sh -c`. Presets are illustrative
          # (4500K mild / 3000K strong) - matches Hyprland's old three-way split
          # (blue-light-filter / off / blue-light-filter2), adjust to taste.
          "SUPER+CTRL,a,spawn,sh -c 'pkill gammastep; exec ${gammastep} -O 4500'"
          "SUPER+CTRL,s,spawn,pkill gammastep"
          "SUPER+CTRL,d,spawn,sh -c 'pkill gammastep; exec ${gammastep} -O 3000'"

          # --- focus (direction-based, confirmed dispatcher: focusdir) ---
          "SUPER,h,focusdir,left"
          "SUPER,l,focusdir,right"
          "SUPER,k,focusdir,up"
          "SUPER,j,focusdir,down"

          # --- swap window in tiling (direction-based) ---
          # move_client (not exchange_client - switched after confirming the difference in
          # src/dispatch/bind.c): swaps the focused tiled window with its neighbor in that
          # direction same as exchange_client, but ALSO jumps the window to the next monitor
          # when there's no neighbor there (client_jump_to_monitor) - exchange_client has no
          # such fallback and just no-ops at a monitor's edge. This is what makes
          # SUPER+SHIFT+hjkl send across monitors, not just swap within one.
          "SUPER+SHIFT,h,move_client,left"
          "SUPER+SHIFT,l,move_client,right"
          "SUPER+SHIFT,k,move_client,up"
          "SUPER+SHIFT,j,move_client,down"

          # --- tags (1:1 port of the old Hyprland 13-workspace scheme) ---
          # tagsilent = send focused window to that tag WITHOUT switching your view there
          # (Hyprland's SUPER+SHIFT+N "move, don't follow"). Plain "tag" (not used here)
          # unconditionally calls client_switch_view - confirmed from mangowc's own
          # src/manage/client.c, no flag suppresses that - so it's not usable for a
          # move-without-follow bind at all; "tagsilent" is the dispatcher that actually
          # skips the view switch (src/dispatch/bind.c: tag_silent() never calls
          # client_switch_view, unlike tag_client()).
          #
          # Focusing a tag uses "viewcrossmon,<tag>,<monitor>", NOT plain "view,<tag>" -
          # plain view always acts on server.selected_monitor (whichever monitor currently
          # has input focus), confirmed from src/dispatch/bind.c's view/focus_direction
          # paths. That's exactly the bug reported live: pressing SUPER+d while focused on
          # DP-3 switched DP-3 itself to tag 10 instead of showing tag 10 (where
          # transmission/terminal actually are) on HDMI-A-1. viewcrossmon's implementation
          # (src/dispatch/bind.c: view_cross_monitor()) calls focus_monitor() on the named
          # output FIRST, then switches that monitor's view - so it always lands tag N on
          # its designated monitor regardless of which monitor you were on. Monitor groups
          # are the exact DP-3/HDMI-A-1 split from the old Hyprland config.custom.displays
          # (hosts/desktop/home.nix): DP-3 gets 1,2,5(q),8(a),11(z),12(x); HDMI-A-1 gets
          # 3,4,6(w),7(e),9(s),10(d),13(c).
          "SUPER,1,viewcrossmon,1,DP-3"
          "SUPER,2,viewcrossmon,2,DP-3"
          "SUPER,3,viewcrossmon,3,HDMI-A-1"
          "SUPER,4,viewcrossmon,4,HDMI-A-1"
          "SUPER,5,viewcrossmon,5,DP-3"
          "SUPER,q,viewcrossmon,5,DP-3"
          "SUPER,6,viewcrossmon,6,HDMI-A-1"
          "SUPER,w,viewcrossmon,6,HDMI-A-1"
          "SUPER,7,viewcrossmon,7,HDMI-A-1"
          "SUPER,e,viewcrossmon,7,HDMI-A-1"
          "SUPER,8,viewcrossmon,8,DP-3"
          "SUPER,a,viewcrossmon,8,DP-3"
          "SUPER,9,viewcrossmon,9,HDMI-A-1"
          "SUPER,s,viewcrossmon,9,HDMI-A-1"
          "SUPER,0,viewcrossmon,10,HDMI-A-1"
          "SUPER,d,viewcrossmon,10,HDMI-A-1"
          "SUPER,z,viewcrossmon,11,DP-3"
          "SUPER,x,viewcrossmon,12,DP-3"
          "SUPER,c,viewcrossmon,13,HDMI-A-1"
          "SUPER+SHIFT,1,tagsilent,1"
          "SUPER+SHIFT,2,tagsilent,2"
          "SUPER+SHIFT,3,tagsilent,3"
          "SUPER+SHIFT,4,tagsilent,4"
          "SUPER+SHIFT,5,tagsilent,5"
          "SUPER+SHIFT,q,tagsilent,5"
          "SUPER+SHIFT,6,tagsilent,6"
          "SUPER+SHIFT,w,tagsilent,6"
          "SUPER+SHIFT,7,tagsilent,7"
          "SUPER+SHIFT,e,tagsilent,7"
          "SUPER+SHIFT,8,tagsilent,8"
          "SUPER+SHIFT,a,tagsilent,8"
          "SUPER+SHIFT,9,tagsilent,9"
          "SUPER+SHIFT,s,tagsilent,9"
          "SUPER+SHIFT,0,tagsilent,10"
          "SUPER+SHIFT,d,tagsilent,10"
          "SUPER+SHIFT,z,tagsilent,11"
          "SUPER+SHIFT,x,tagsilent,12"
          "SUPER+SHIFT,c,tagsilent,13"

          # --- monitor focus/send (Hyprland: SUPER+CTRL+h/l focus monitor, +j/k send window) ---
          # Confirmed from src/config/value_parse.c (parse_monitor_arg/parse_force): focusmon/
          # tagmon take either a literal output name (used below) or the keywords
          # "next"/"prev" for relative cycling.
          "SUPER+CTRL,l,focusmon,DP-3"
          "SUPER+CTRL,h,focusmon,DP-2"
          "SUPER+CTRL,k,tagmon,DP-2"
          "SUPER+CTRL,j,tagmon,DP-3"
          # Hyprland also had a SEPARATE relative-cycle pair (SUPER+SHIFT+CTRL+h/l ->
          # focus(workspace="m-1"/"m+1")), distinct from the fixed DP-2/DP-3 binds above -
          # this is that one, using focusmon's "prev"/"next" keywords instead of named
          # outputs.
          "SUPER+SHIFT+CTRL,h,focusmon,prev"
          "SUPER+SHIFT+CTRL,l,focusmon,next"

          # --- fullscreen / floating ---
          "SUPER,f,togglefullscreen"
          # Mango DOES have a direct equivalent of Hyprland's SUPER+SHIFT+f fake-fullscreen
          # after all (correcting an earlier note here that claimed otherwise):
          # togglefakefullscreen -> toggle_fake_fullscreen() -> client_set_fake_fullscreen()
          # (src/dispatch/bind.c, src/manage/client.c) sets isfakefullscreen and reports
          # fullscreen to the client without resizing it off its current geometry - same
          # "app thinks it's fullscreen, window stays its real size" semantics as Hyprland's
          # fullscreen_state({internal=-1, client=2}).
          "SUPER+SHIFT,f,togglefakefullscreen"
          "SUPER,n,centerwin" # repurposed - centerwin is a different, genuinely new action
          # (centers a floating window) - put on the freed SUPER+n since Hyprland's SUPER+n
          # was maximize, and togglefullscreen above is the closest single equivalent to that.
          "SUPER,g,togglefloating" # was SUPER+g in Hyprland too, kept as-is
          "SUPER,m,toggleglobal" # best guess for Hyprland's SUPER+CTRL+s window-pin ("sticky,
          # show on all workspaces") - toggleglobal sounds closest in the dispatcher list but
          # wasn't confirmed to be semantically identical, verify once running

          # --- cycle windows (Hyprland: ALT+Tab / ALT+SHIFT+Tab via cycle_next) ---
          "ALT,Tab,focusstack,next"
          "ALT+SHIFT,Tab,focusstack,prev"

          # --- layout (Hyprland: SUPER+m addmaster, SUPER+SHIFT+m removemaster, SUPER+r cycle) ---
          # bracketright/bracketleft instead of equal/minus - under xkb_rules_layout=jp
          # (set below to fix the keyboard layout), "equal" and "minus" resolve to the same
          # physical key (JIS punctuation row differs from ANSI), which mango's own conflict
          # checker caught as a hard build error ("Key binding conflict ... keymode default")
          # once the layout was actually applied. Brackets aren't affected the same way.
          "SUPER,bracketright,incnmaster,1" # closest equivalents using confirmed dispatchers -
          "SUPER,bracketleft,incnmaster,-1" # incnmaster for master-count instead of Hyprland's
          # addmaster/removemaster (different mental model: Hyprland adds/removes specific master
          # slots, Mango's incnmaster increments a count - similar end result, not identical).
          # SUPER+r was reassigned above to reload_config (a direct, more universal binding) since
          # Mango's layout-cycling equivalent of Hyprland's "orientationcycle" wasn't confirmed to
          # exist as a single dispatcher - use setlayout directly instead, bound separately below.
          "SUPER+ALT,s,setlayout,scroller"
          "SUPER+ALT,d,setlayout,dwindle"
          "SUPER+ALT,space,setlayout,monocle"

          # --- audio (unrelated to the compositor, same commands work regardless) ---
          "none,XF86AudioLowerVolume,spawn,${pamixer} -d 5"
          "none,XF86AudioRaiseVolume,spawn,${pamixer} -i 5"
          "none,XF86AudioMute,spawn,${pamixer} -t"
        ] ++ lib.optionals config.custom.backlight.enable [
          "none,XF86MonBrightnessDown,spawn,${lib.getExe pkgs.brightnessctl} set 5%-"
          "none,XF86MonBrightnessUp,spawn,${lib.getExe pkgs.brightnessctl} set +5%"
        ] ++ [
          "SUPER,v,setkeymode,resize" # was SUPER+e - that collided with the new tag bind for
          # e (7, reaper) once letters became real tag keys, not just unused letters
          "SUPER,space,spawn,fuzzel" # launcher alternative to rofi - remove if you'd rather
          # just use SUPER+SHIFT+Return (rofi) for everything and not install fuzzel at all
        ];

        # Confirmed live: triggering moveresize from a keyboard key (SUPER+Zenkaku_Hankaku)
        # was genuinely broken, not just differently-behaved - it starts the grab fine on
        # keypress, but nothing ever ends it, because src/input/keyboard.c has zero
        # references to cursor_mode anywhere: the grab is only ever cleared on a mouse
        # BUTTON release (src/input/pointer.c), never on a keyboard key release. That left
        # server.grab_client stuck set, which ALSO explains the floating-toggle bug reported
        # alongside this - toggle_floating() (src/dispatch/bind.c) opens with
        # `if (!server.selected_monitor || server.grab_client) return 0;`, so a stuck grab
        # silently no-ops every togglefloating press too. Reverting to mousebind, which
        # starts the grab on button press and properly ends it on button release - actual
        # hold-and-drag semantics, not achievable from a keyboard key at all here.
        mousebind = [
          "SUPER,btn_left,moveresize,curmove"
          "SUPER,btn_right,moveresize,curresize"
        ];

        key_mode.resize.bind = [
          "NONE,Left,resizewin,-20,+0"
          "NONE,Right,resizewin,+20,+0"
          "NONE,Up,resizewin,+0,-20"
          "NONE,Down,resizewin,+0,+20"
          "NONE,Escape,setkeymode,default"
          "NONE,Return,setkeymode,default"
        ];

        # Native equivalent of Hyprland startup.nix's "[workspace N silent] cmd" exec trick -
        # assigns an app to a tag by app_id regardless of how/when it's launched, instead of
        # having to wrap every launch command. is_tag_silent:1 mirrors Hyprland's "silent" (don't
        # yank focus to that tag when the window opens). Syntax (window_rule=tags:N,app_id:...,
        # is_tag_silent:1,...) confirmed from DreamMaoMao's own real-world rule.conf, which is
        # also where the exact com.obsproject.Studio app_id below comes from.
        #
        # app_id confirmed against this repo's existing Hyprland window/class rules: librewolf,
        # REAPER, vesktop, mpv (home-manager/hyprland/{keybinds,default}.nix,
        # home-manager/hyprland/startup.nix). telegram-desktop, transmission-remote-gtk,
        # qjackctl, pavucontrol, steam are my best-guess app_ids (common nixpkgs WM_CLASS
        # convention), NOT verified against this specific system - check with
        # `mmsg get window` (or whatever mango's IPC query command turns out to be) while the
        # app is focused, and fix the app_id string here if it doesn't match.
        window_rule = [
          "tags:1,app_id:vesktop" # discord
          "tags:5,is_tag_silent:1,app_id:librewolf" # q - browser
          "tags:6,app_id:steam" # w - steam/games (UNVERIFIED app_id)
          "tags:7,app_id:REAPER" # e
          "tags:8,is_tag_silent:1,app_id:org.telegram.desktop" # a - telegram (UNVERIFIED app_id)
          "tags:10,app_id:mpv" # d - media viewing
          "tags:10,is_tag_silent:1,app_id:transmission-remote-gtk" # d (UNVERIFIED app_id)
          # Companion terminal for tag 10, matched by title instead of app_id since app_id
          # "kitty" alone would catch every terminal, not just this one - mirrors Hyprland
          # startup.nix spawning kitty+transmission-remote-gtk together in ~/_CURRENT (see
          # autostart_sh below for the actual spawn).
          "tags:10,is_tag_silent:1,title:current-media"
          "tags:11,app_id:com.obsproject.Studio" # z - OBS
          "tags:13,app_id:Pavucontrol" # c - audio control (UNVERIFIED app_id)
          "tags:13,app_id:qjackctl" # c - audio control (UNVERIFIED app_id)
          # s (9, "another game/steam") and x (12, misc) are intentionally left as plain
          # unassigned tags - they're where you manually move whatever's using them that day,
          # not tied to one fixed app.
        ];
      };

      autostart_sh = ''
        ironbar &
        # Was missing entirely - the actual cause of "wrong keyboard layout in effect" /
        # fcitx not in the tray. Hyprland's startup.nix starts this the same bare way.
        fcitx5 &
        # Paired with the "tags:5,app_id:librewolf" window_rule above - the rule only routes
        # it to tag 5 (q) once it's open, it doesn't launch it. Mirrors Hyprland startup.nix's
        # openOnWorkspace 5 "librewolf".
        librewolf &
        # Paired with the "tags:10,title:current-media" window_rule above - lands together
        # with transmission-remote-gtk on tag 10 (d), same grouping Hyprland startup.nix used.
        kitty --title current-media --directory ~/_CURRENT &
        transmission-remote-gtk &
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

    home.packages = [ pkgs.ironbar pkgs.gammastep pkgs.monocraft ];

    # Styling - mirrors home-manager/hyprland/waybar.nix's wallust "waybar.css" template as
    # closely as ironbar's selector set allows (confirmed from ironbar's own Styling guide:
    # `.background`/`#bar` for the bar itself, `.widget` for "any widget" - the equivalent of
    # waybar's per-module baseModuleCss applied broadly rather than per-class). Font changed
    # to Monocraft per request (added to home.packages above so fontconfig actually has it);
    # background set to a solid #1C1A1C rather than copying waybar's literal
    # `rgba(0,0,0,0.0)` - that one was fully transparent, not a solid color to port over.
    xdg.configFile."ironbar/style.css".text = ''
      * {
        border: none;
        border-radius: 0;
      }

      .background,
      #bar {
        background-color: #1C1A1C;
      }

      .widget {
        font-family: "Monocraft";
        font-weight: bold;
        font-size: 14px;
        color: #fecdb2;
        text-shadow: 1px 1px 2px rgba(0, 0, 0, 0.8);
      }
    '';

    # Module set/order deliberately mirrors home-manager/hyprland/waybar.nix's
    # modules-left / modules-center / modules-right, using ironbar's nearest native
    # equivalent for each (see per-module notes below). Two things don't carry over:
    #   - "hyprland/workspaces" (waybar's modules-center): ironbar's workspaces module
    #     only supports Sway, Hyprland and Niri (its own docs), not Mango - left out
    #     entirely rather than shipping a module that can't work.
    #   - "custom/shade" and "custom/nix" (hyprshade blue-light-filter toggle and the
    #     hypr-wallpaper/wallpapers-select buttons): both call Hyprland-only scripts
    #     with no Mango-side equivalent built yet, so they're dropped rather than
    #     wired to something that would silently no-op.
    #
    # Pinned to the DP-3 output only via the top-level "monitors" map (leaving the
    # implicit top-level start/center/end unset hides the bar on every other output) -
    # DP-3 is always present in both monitor states (the 5120x1440 single-wide mode and
    # the split-PBP 2560x1440 DP-3+HDMI-A-1 mode, see settings.monitor_rule above), so
    # this keeps the bar off HDMI-A-1 in either case without needing to special-case it.
    # Built as a Nix attrset and serialized via pkgs.formats.yaml rather than hand-spliced
    # ''...'' heredocs - each ''...'' literal strips its OWN minimum indentation
    # independently, so concatenating conditional fragments (lib.optionalString ...) written
    # at a different indent than their surrounding block silently misaligns the YAML nesting
    # (a real bug caught here before shipping: the brightness/battery fragments were landing
    # at column 0 instead of nested under start:/end:). Building the data in Nix and letting
    # the generator emit correct YAML sidesteps that whole class of bug.
    xdg.configFile."ironbar/config.yaml".source =
      (pkgs.formats.yaml { }).generate "ironbar-config.yaml" {
        # Pinned to DP-3 only - leaving the implicit top-level start/center/end unset hides
        # the bar on every other output. DP-3 is always present in both monitor states (the
        # 5120x1440 single-wide mode and the split-PBP 2560x1440 DP-3+HDMI-A-1 mode, see
        # settings.monitor_rule above), so this keeps the bar off HDMI-A-1 either way.
        monitors."DP-3" = {
          position = "top";
          height = 32;
          # Module set/order mirrors home-manager/hyprland/waybar.nix's modules-left, using
          # ironbar's nearest native equivalent for each. Two things don't carry over:
          #   - "hyprland/workspaces" (waybar's modules-center): ironbar's workspaces module
          #     only supports Sway, Hyprland and Niri (its own docs), not Mango - left out
          #     entirely rather than shipping a module that can't work.
          #   - "custom/shade" and "custom/nix" (hyprshade blue-light-filter toggle, and the
          #     hypr-wallpaper/wallpapers-select buttons): both call Hyprland-only scripts
          #     with no Mango-side equivalent built yet, dropped rather than wired to
          #     something that would silently no-op.
          start = [
            {
              type = "custom";
              bar = [
                {
                  type = "button";
                  # on_click_left/on_click_right are generic module-level event hooks
                  # (present on every module/widget, not just the button widget's own single
                  # "on_click") - confirmed from ironbar's wiki Configuration guide, section
                  # 3.2. Left click keeps the ISO toggle; right click re-opens the native
                  # calendar popup via the special "popup:toggle" bar command (the same
                  # command Custom.md's own power-menu example uses on a button's on_click -
                  # UNVERIFIED whether it also works from on_click_right specifically rather
                  # than only the widget's primary on_click, test live).
                  on_click_left = "!${ironbarClockToggle}";
                  on_click_right = "popup:toggle";
                  widgets = [
                    { type = "label"; label = "{{1000:${ironbarClockLabel "󰥔 %H:%M:%S 󰸗 %a, %d %b %Y"}}}"; }
                  ];
                }
              ];
              # Re-nests a plain native clock widget (disable_popup so IT doesn't try to open
              # a popup of its own) as the content of OUR popup - same pattern Custom.md's own
              # power-menu example uses to embed a clock in a custom popup. This is what
              # right-click now opens: the actual calendar, unchanged from ironbar's built-in
              # clock widget.
              popup = [
                { type = "clock"; disable_popup = true; }
              ];
            }
            {
              type = "sys_info";
              # memory + temperature + cpu + network, one label each - same grouping/order as
              # the four separate waybar modules they replace. temp_c sensor id ("CPUTIN") is
              # a guess at the lm-sensors label for this board, NOT confirmed - check `sensors`
              # output and fix if that label shows nothing.
              format = [
                " {memory_used}/{memory_total}GB ({memory_percent}%)"
                " {temp_c@CPUTIN}°C"
                " {cpu_percent}% @ {cpu_frequency}GHz"
                "󰓢 {net_down@eno1}/{net_up@eno1}Mbps"
              ];
              interval = { memory = 3; temps = 3; cpu = 3; networks = 3; };
            }
            {
              type = "volume";
              format = "{icon}  {percentage}%";
              mute_format = "{icon}  Muted";
              icons = { volume = "󰕾"; muted = "󰖁"; };
              profiles = {
                medium = { when = 66.66; icons.volume = "󰖀"; };
                low = { when = 33.33; icons.volume = "󰕿"; };
              };
            }
          ]
          ++ lib.optional config.custom.backlight.enable { type = "brightness"; }
          ++ [
            (
              let
                brightnessDdc = lib.getExe config.custom.shell.packages.brightness-ddc;
              in
              {
                # External DP monitor brightness via DDC/CI, not ironbar's native
                # "brightness" module above (that one is backlight/keyboard-LED only -
                # confirmed from its docs, mode.subsystem is "backlight" or "leds", no DDC
                # option - meaningless for an external monitor with no internal panel).
                # Reuses the same debounced ddcutil script waybar.nix already defined
                # (custom.shell.packages.brightness-ddc) instead of duplicating its
                # scroll-flooding fix.
                type = "custom";
                on_click_left = "!${brightnessDdc} set 0";
                on_click_right = "!${brightnessDdc} set 100";
                on_click_middle = "!${brightnessDdc} toggle";
                on_scroll_up = "!${brightnessDdc} up 10";
                on_scroll_down = "!${brightnessDdc} down 10";
                bar = [
                  { type = "label"; label = "{{10000:${brightnessDdc} get}}%"; }
                ];
              }
            )
            { type = "tray"; direction = "horizontal"; icon_size = 16; }
            { type = "inhibit"; }
          ];
          center = [ ];
          # waybar modules-right order: hyprland/window, battery (if enabled), clock
          end = [
            { type = "focused"; show_icon = true; show_title = true; truncate = "end"; }
          ]
          ++ lib.optional config.custom.battery.enable { type = "battery"; format = "{percentage}%"; }
          ++ [
            {
              type = "custom";
              bar = [
                {
                  type = "button";
                  on_click_left = "!${ironbarClockToggle}";
                  on_click_right = "popup:toggle";
                  widgets = [
                    { type = "label"; label = "{{1000:${ironbarClockLabel "󰥔 %H:%M"}}}"; }
                  ];
                }
              ];
              popup = [
                { type = "clock"; disable_popup = true; }
              ];
            }
          ];
        };
      };
  };
}

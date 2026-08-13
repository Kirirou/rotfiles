{
  config,
  lib,
  pkgs,
  ...
}:
let
  pamixer = lib.getExe pkgs.pamixer;
in
{
  wayland.windowManager.hyprland = lib.mkIf config.wayland.windowManager.hyprland.enable {
    extraConfig = ''
      -- non-consuming pass-through
      hl.bind("code:70", hl.dsp.pass({ window = "class:^(vesktop)$" }), { non_consuming = true })
      hl.bind("code:115", hl.dsp.pass({ window = "class:^(vesktop)$" }), { non_consuming = true })
      hl.bind("code:70", hl.dsp.exec_cmd("notify-send hello"), { non_consuming = true })

      -- mouse pass-through
      hl.bind("mouse:275", hl.dsp.pass({ window = "class:^(librewolf)$" }))

      -- exec
      hl.bind("SUPER + Return", hl.dsp.exec_cmd("${lib.getExe pkgs.kitty}"))
      hl.bind("SUPER + SHIFT + Return", hl.dsp.exec_cmd("rofi -show drun"))
      -- kill
      hl.bind("SUPER + BackSpace", hl.dsp.window.close())
      hl.bind("SUPER + CTRL + BackSpace", hl.dsp.exec_cmd("hyprctl kill"))
      hl.bind("SUPER + Escape", hl.dsp.window.close())
      -- file
      hl.bind("SUPER + b", hl.dsp.exec_cmd("nemo ~/Downloads"))
      -- exit hyprland
      hl.bind("SUPER + CTRL + 5", hl.dsp.exit())
      hl.bind("SUPER + CTRL + Return", hl.dsp.exec_cmd("rofi -show power-menu -font \"${config.custom.fonts.monospace} 14\" -modi power-menu:rofi-power-menu"))
      hl.bind("SUPER + CTRL + v", hl.dsp.exec_cmd("cliphist list | rofi -dmenu | cliphist decode | wl-copy"))
      -- reset monitors
      hl.bind("CTRL + SHIFT + Escape", hl.dsp.exec_cmd("hypr-monitors"))
      -- lighting
      hl.bind("SUPER + CTRL + a", hl.dsp.exec_cmd("hyprshade on blue-light-filter"))
      hl.bind("SUPER + CTRL + s", hl.dsp.exec_cmd("hyprshade off"))
      hl.bind("SUPER + CTRL + d", hl.dsp.exec_cmd("hyprshade on blue-light-filter2"))
      -- focus
      hl.bind("SUPER + h", hl.dsp.focus({ direction = "left" }))
      hl.bind("SUPER + l", hl.dsp.focus({ direction = "right" }))
      hl.bind("SUPER + k", hl.dsp.focus({ direction = "up" }))
      hl.bind("SUPER + j", hl.dsp.focus({ direction = "down" }))
      -- move window
      hl.bind("SUPER + SHIFT + h", hl.dsp.window.move({ direction = "left" }))
      hl.bind("SUPER + SHIFT + l", hl.dsp.window.move({ direction = "right" }))
      hl.bind("SUPER + SHIFT + k", hl.dsp.window.move({ direction = "up" }))
      hl.bind("SUPER + SHIFT + j", hl.dsp.window.move({ direction = "down" }))
      -- workspaces
      hl.bind("SUPER + 1", hl.dsp.focus({ workspace = 1 }))
      hl.bind("SUPER + 2", hl.dsp.focus({ workspace = 2 }))
      hl.bind("SUPER + 3", hl.dsp.focus({ workspace = 3 }))
      hl.bind("SUPER + 4", hl.dsp.focus({ workspace = 4 }))
      hl.bind("SUPER + 5", hl.dsp.focus({ workspace = 5 }))
      hl.bind("SUPER + q", hl.dsp.focus({ workspace = 5 }))
      hl.bind("SUPER + 6", hl.dsp.focus({ workspace = 6 }))
      hl.bind("SUPER + w", hl.dsp.focus({ workspace = 6 }))
      hl.bind("SUPER + 7", hl.dsp.focus({ workspace = 7 }))
      hl.bind("SUPER + e", hl.dsp.focus({ workspace = 7 }))
      hl.bind("SUPER + 8", hl.dsp.focus({ workspace = 8 }))
      hl.bind("SUPER + a", hl.dsp.focus({ workspace = 8 }))
      hl.bind("SUPER + 9", hl.dsp.focus({ workspace = 9 }))
      hl.bind("SUPER + s", hl.dsp.focus({ workspace = 9 }))
      hl.bind("SUPER + 0", hl.dsp.focus({ workspace = 10 }))
      hl.bind("SUPER + d", hl.dsp.focus({ workspace = 10 }))
      hl.bind("SUPER + x", hl.dsp.focus({ workspace = 12 }))
      hl.bind("SUPER + c", hl.dsp.focus({ workspace = 13 }))
      -- move window to workspace
      hl.bind("SUPER + SHIFT + 1", hl.dsp.window.move({ workspace = 1, follow = false }))
      hl.bind("SUPER + SHIFT + 2", hl.dsp.window.move({ workspace = 2, follow = false }))
      hl.bind("SUPER + SHIFT + 3", hl.dsp.window.move({ workspace = 3, follow = false }))
      hl.bind("SUPER + SHIFT + 4", hl.dsp.window.move({ workspace = 4, follow = false }))
      hl.bind("SUPER + SHIFT + 5", hl.dsp.window.move({ workspace = 5, follow = false }))
      hl.bind("SUPER + SHIFT + q", hl.dsp.window.move({ workspace = 5, follow = false }))
      hl.bind("SUPER + SHIFT + 6", hl.dsp.window.move({ workspace = 6, follow = false }))
      hl.bind("SUPER + SHIFT + w", hl.dsp.window.move({ workspace = 6, follow = false }))
      hl.bind("SUPER + SHIFT + 7", hl.dsp.window.move({ workspace = 7, follow = false }))
      hl.bind("SUPER + SHIFT + e", hl.dsp.window.move({ workspace = 7, follow = false }))
      hl.bind("SUPER + SHIFT + 8", hl.dsp.window.move({ workspace = 8, follow = false }))
      hl.bind("SUPER + SHIFT + a", hl.dsp.window.move({ workspace = 8, follow = false }))
      hl.bind("SUPER + SHIFT + 9", hl.dsp.window.move({ workspace = 9, follow = false }))
      hl.bind("SUPER + SHIFT + s", hl.dsp.window.move({ workspace = 9, follow = false }))
      hl.bind("SUPER + SHIFT + 0", hl.dsp.window.move({ workspace = 10, follow = false }))
      hl.bind("SUPER + SHIFT + d", hl.dsp.window.move({ workspace = 10, follow = false }))
      hl.bind("SUPER + SHIFT + x", hl.dsp.window.move({ workspace = 12, follow = false }))
      hl.bind("SUPER + SHIFT + c", hl.dsp.window.move({ workspace = 13, follow = false }))
      -- monitor cycling
      hl.bind("SUPER + SHIFT + CTRL + h", hl.dsp.focus({ workspace = "m-1" }))
      hl.bind("SUPER + SHIFT + CTRL + l", hl.dsp.focus({ workspace = "m+1" }))
      -- monocle / fullscreen
      hl.bind("SUPER + n", hl.dsp.window.fullscreen({ mode = "maximized" }))
      hl.bind("SUPER + f", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
      hl.bind("SUPER + SHIFT + f", hl.dsp.window.fullscreen_state({ internal = -1, client = 2 }))
      -- floating / sticky
      hl.bind("SUPER + g", hl.dsp.window.float({ action = "toggle" }))
      hl.bind("SUPER + CTRL + s", hl.dsp.window.pin())
      -- focus monitor
      hl.bind("SUPER + CTRL + l", hl.dsp.focus({ monitor = "DP-3" }))
      hl.bind("SUPER + CTRL + h", hl.dsp.focus({ monitor = "DP-2" }))
      hl.bind("SUPER + CTRL + k", hl.dsp.window.move({ monitor = "DP-2" }))
      hl.bind("SUPER + CTRL + j", hl.dsp.window.move({ monitor = "DP-3" }))
      -- resize
      hl.bind("SUPER + Left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }))
      hl.bind("SUPER + Right", hl.dsp.window.resize({ x = 0, y = 50, relative = true }))
      hl.bind("SUPER + Up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }))
      hl.bind("SUPER + Down", hl.dsp.window.resize({ x = 50, y = 0, relative = true }))
      -- cycle windows
      hl.bind("ALT + Tab", hl.dsp.window.cycle_next({}))
      hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))
      -- misc
      hl.bind("SUPER + p", hl.dsp.exec_cmd("hypr-pip"))
      hl.bind("SUPER + m", hl.dsp.layout("addmaster"))
      hl.bind("SUPER + SHIFT + m", hl.dsp.layout("removemaster"))
      hl.bind("SUPER + r", hl.dsp.layout("orientationcycle left top"))
      hl.bind("SUPER + CTRL + r", hl.dsp.exec_cmd("hyprctl reload"))
      hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
      hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
      hl.bind("SUPER + grave", hl.dsp.exec_cmd("dunstctl history-pop"))
      hl.bind("SUPER + apostrophe", hl.dsp.exec_cmd("imv-wallpaper"))
      hl.bind("SUPER + SHIFT + comma", hl.dsp.exec_cmd("rofi-wallust-theme"))
      -- audio
      hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("${pamixer} -d 5"))
      hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("${pamixer} -i 5"))
      hl.bind("XF86AudioMute", hl.dsp.exec_cmd("${pamixer} -t"))
      hl.bind("SUPER + n", hl.dsp.exec_cmd("hypr-wallpaper"))
      ${lib.optionalString config.custom.backlight.enable ''
      hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("${lib.getExe pkgs.brightnessctl} set 5%-"))
      hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("${lib.getExe pkgs.brightnessctl} set +5%"))
      ''}
      -- mouse drag/resize
      hl.bind("SUPER + code:49", hl.dsp.window.drag(), { mouse = true })
      hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
    '';
  };
}

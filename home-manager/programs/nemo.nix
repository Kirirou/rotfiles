{
  config,
  lib,
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    krusader
    nemo-fileroller
    webp-pixbuf-loader # for webp thumbnails
    nemo-with-extensions
  ];

  xdg = {
    # fix mimetype associations
    mimeApps.defaultApplications = {
      "inode/directory" = "nemo.desktop";
      # wtf zathura / pqiv registers themselves to open archives
      "application/zip" = "org.gnome.FileRoller.desktop";
      "application/vnd.rar" = "org.gnome.FileRoller.desktop";
      "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
      "application/x-bzip2-compressed-tar" = "org.gnome.FileRoller.desktop";
    };

    configFile =
      {
        "mimeapps.list".force = true;
      }
      # other OSes seem to override this file
      ;
  };

  gtk.gtk3.bookmarks =
    let
      homeDir = config.home.homeDirectory;
    in
    [
      # "file://${homeDir}/Downloads Downloads"
      # "file://${homeDir}/Videos Videos"
      # "file://${homeDir}/Pictures Pictures"
      # "file://${homeDir}/Pictures/Wallpapers WALLPAPERS"
      # "file://${homeDir}/pr PR"
      # "file://${homeDir}/pr/rotfiles ROTS"
      # "file:///persist PERSIST"
    ];

  dconf.settings = {
    # fix vm
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = ["qemu:///system"];
      uris = ["qemu:///system"];
    };
    # fix open in terminal
    "org/gnome/desktop/applications/terminal" = {
      exec = lib.getExe config.custom.terminal.package;
    };
    "org/cinnamon/desktop/applications/terminal" = {
      exec = lib.getExe config.custom.terminal.package;
    };
    "org/nemo/preferences" = {
      default-folder-viewer = "list-view";
      show-hidden-files = true;
      start-with-dual-pane = true;
      date-format-monospace = true;
      # needs to be a uint64!
      thumbnail-limit = lib.hm.gvariant.mkUint64 (100 * 1024 * 1024); # 100 mb
    };
    "org/nemo/window-state" = {
      sidebar-bookmark-breakpoint = 0;
      sidebar-width = 180;
    };
    "org/nemo/preferences/menu-config" = {
      selection-menu-make-link = true;
      selection-menu-copy-to = true;
      selection-menu-move-to = true;
    };
  };

  wayland.windowManager.hyprland.settings = {
    # disable transparency for file delete dialog
    window_rule = [
      { match.class = "nemo"; float = true; force_rgbx = true; }
      { match.class = "org.kde.krusader"; float = true; force_rgbx = true; }
    ];
  };

  custom.persist = {
    home = {
      files = [ ".config/krusaderrc" ];
      directories = [
        # folder preferences such as view mode and sort order
        ".local/share/gvfs-metadata"
      ];
      cache = [
        # thumbnail cache
        ".cache/thumbnails"
      ];
    };
  };
}

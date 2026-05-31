{
  config,
  pkgs,
  user,
  lib,
  ...
}: {
  config = {
    # Select internationalisation properties.
    i18n = {
      inputMethod = {
        # enabled = "fcitx5";
        enable = true;
        type = "fcitx5";
        fcitx5.waylandFrontend = true;
        fcitx5.addons = with pkgs; [
          # fcitx5-mozc
          fcitx5-anthy
          fcitx5-gtk
          kdePackages.fcitx5-qt
        ];
      };
    };
    # environment.systemPackages = [pkgs.tagainijisho ];
    custom.persist = {
      home.directories = [
        ".config/fcitx/"
        ".config/fcitx5/"
      ];
    };
    services.xserver.xkb = {
      layout = config.custom.xkbLayout;
      variant = "";
      options = "compose:ralt";
    };

    # KEYMAPS
    console = {
      packages = [pkgs.terminus_font];
      # seems to break virtual-console service because it can't find the font
      # https://github.com/NixOS/nixpkgs/issues/257904
      font = "${pkgs.terminus_font}/share/consolefonts/ter-112n.psf.gz";

      useXkbConfig = true; # use xkb.options in tty.
    };
    # services.gpm.enable = true;

    # piper
    services.ratbagd.enable = true;

    users.users.${user} = {...}: {
      extraGroups = ["input"];
    };

    environment.variables = {
      # GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
      GLFW_IM_MODULE = "fcitx";

      GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPath "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
        gstreamer.out
        gst-plugins-base
        gst-plugins-good
        (gst-plugins-bad.override { lv2 = null; })
        gst-plugins-ugly
        gst-libav
      ]);
    };
  };
}

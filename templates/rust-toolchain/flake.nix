{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    fenix.url = "github:nix-community/fenix";
  };

  outputs =
    inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.devenv.flakeModule ];
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem =
        {
          config,
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        let
          libraries = with pkgs; [
            # webkitgtk
            webkitgtk_4_1
            # webkitgtk_6_0
            gtk3
            cairo
            gdk-pixbuf
            glib
            dbus
            openssl_3
            librsvg

            # Bevy
            alsa-lib
            vulkan-tools
            vulkan-headers
            vulkan-loader
            vulkan-validation-layers
            udev
            clang
            lld
            libsoup_3

            libGL
            libX11
            libX11
            libXcursor
            libXi
            libXrandr
            libxkbcommon
            wayland

            # Video/Audio data composition framework tools like "gst-inspect", "gst-launch" ...
            gst_all_1.gstreamer
            # Common plugins like "filesrc" to combine within e.g. gst-launch
            gst_all_1.gst-plugins-base
            # Specialized plugins separated by quality
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-plugins-ugly
            # Plugins to reuse ffmpeg to play almost every video format
            gst_all_1.gst-libav
            # Support the Video Audio (Hardware) Acceleration API
            gst_all_1.gst-vaapi
          ];

          packages = with pkgs; [
            # Video/Audio data composition framework tools like "gst-inspect", "gst-launch" ...
            gst_all_1.gstreamer
            # Common plugins like "filesrc" to combine within e.g. gst-launch
            gst_all_1.gst-plugins-base
            # Specialized plugins separated by quality
            gst_all_1.gst-plugins-good
            gst_all_1.gst-plugins-bad
            gst_all_1.gst-plugins-ugly
            # Plugins to reuse ffmpeg to play almost every video format
            gst_all_1.gst-libav
            # Support the Video Audio (Hardware) Acceleration API
            gst_all_1.gst-vaapi

            # Bevy
            alsa-lib
            vulkan-tools
            vulkan-headers
            vulkan-loader
            vulkan-validation-layers
            udev
            clang
            lld

            libGL
            libX11
            libX11
            libXcursor
            libXi
            libXrandr
            libxkbcommon
            wayland

            curl
            wget
            pkg-config
            dbus
            openssl_3
            glib
            gtk3
            libsoup_3
            # webkitgtk
            webkitgtk_4_1
            # webkitgtk_6_0
            librsvg

            bacon
          ];
        in
        {
          devenv.shells.default = {
            # https://devenv.sh/reference/options/
            dotenv.disableHint = true;

            packages = packages;

            languages.javascript = {
              enable = true;
              corepack.enable = true;
              npm = {
                enable = true;
                install.enable = true;
              };
            };
            languages.typescript.enable = true;

            languages.rust = {
              enable = true;
              channel = "nightly";
              toolchain = {
                rustc = pkgs.rustc;
              };
              targets = [ "wasm32-unknown-unknown" ];
            };

            env = {
              LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH";
              XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS";
            };
          };
        };
    };
}

{
  config,
  pkgs,
  pkgs-stable,
  lib,
  user,
  ...
}: {
config = lib.mkIf config.custom.reaper.enable {
  home = {
    packages = [
      # DAW:
      # -----
      pkgs.reaper
      pkgs.reaper-sws-extension

      # PLUGINS:
      # --------
      pkgs.helm
      # pkgs.sorcer
      pkgs.oxefmsynth
      # pkgs.fmsynth
      pkgs.aether-lv2
      pkgs.bespokesynth
      pkgs.x42-plugins
      pkgs.fluidsynth
      pkgs.airwindows-lv2
      pkgs.mda_lv2
      pkgs.drumkv1
      pkgs.drumgizmo
      pkgs.hydrogen
      pkgs.x42-avldrums
      pkgs.rkrlv2
      pkgs.swh_lv2
      pkgs.neural-amp-modeler-lv2
      # pkgs.tunefish
      pkgs.soundfont-generaluser
      pkgs.soundfont-ydp-grand
      pkgs.noise-repellent
      pkgs.speech-denoiser
      pkgs.mod-distortion
      pkgs.midi-trigger
      pkgs.sfizz
      pkgs.carla
      # pkgs.distrho
      pkgs.bshapr
      pkgs.bchoppr
      pkgs.fomp
      pkgs.gxplugins-lv2
      pkgs.fverb
      pkgs.mooSpace
      pkgs.boops
      # pkgs.artyFX
      pkgs.zam-plugins
      pkgs.molot-lite
      pkgs.bankstown-lv2
      pkgs.vital

      # pkgs.decent-sampler
      pkgs.custom.decent-sampler-dynamic
      pkgs.custom.sfizz-lv2
      # LIB
      # -------
      pkgs.expat
      # pkgs.ecasound
    ]
    # NOTE: https://discourse.nixos.org/t/lmms-vst-plugins/42985/3
    # To add it to yabridge, we just have to add the common path for plugins:
    # $ yabridgectl add "~/.wine/drive_c/VST2"
    # Then, after we run the sync command, all plugins should be detected and loaded:
    # $ yabridgectl sync
    # If you want to know which plugins are loaded, just run the following command and it will show you the path and type for each plugin and if it’s synced or not:
    # $ yabridgectl status
    ++ [
      # pkgs.yabridge
      # pkgs.yabridgectl
      pkgs-stable.yabridge
      pkgs-stable.yabridgectl
    ];

    # just a NOTE: that plugins are installed into these directories:
    # `/etc/profiles/per-user/${user}/lib/lv2`
    # `/etc/profiles/per-user/${user}/lib/lxvst`

    # persist plugins
    # sessionVariables = {
    #   LV2_PATH = "~/.nix-profile/lib/lv2/:~/.lv2:/nix/var/nix/profiles/default/lib/lv2:/var/run/current-system/sw/lib/lv2";
    #   VST_PATH = "~/.nix-profile/lib/vst/:~/.vst:/nix/var/nix/profiles/default/lib/vst:/var/run/current-system/sw/lib/vst";
    #   LXVST_PATH = "~/.nix-profile/lib/lxvst/:~/.lxvst:/nix/var/nix/profiles/default/lib/lxvst:/var/run/current-system/sw/lib/lxvst";
    #   LADSPA_PATH = "~/.nix-profile/lib/ladspa/:~/.ladspa:/nix/var/nix/profiles/default/lib/ladspa:/var/run/current-system/sw/lib/ladspa";
    #   DSSI_PATH = "~/.nix-profile/lib/dssi/:~/.dssi:/nix/var/nix/profiles/default/lib/dssi:/var/run/current-system/sw/lib/dssi";
    # };
    sessionVariables = let
      makePluginPath = format:
      (lib.makeSearchPath format [
        "$HOME/.nix-profile/lib"
        "/run/current-system/sw/lib"
        "/etc/profiles/per-user/$USER/lib"
      ])
      + ":$HOME/.${format}";
    in {
      DSSI_PATH = makePluginPath "dssi";
      LADSPA_PATH = makePluginPath "ladspa";
      LV2_PATH = makePluginPath "lv2";
      LXVST_PATH = makePluginPath "lxvst";
      VST_PATH = makePluginPath "vst";
      VST3_PATH = makePluginPath "vst3";
      };
    };

    # OSC send for muting tracks in REAPER
    # q w e r t y   → ARM ON   (tracks 1–6)
    # a s d f g h   → ARM OFF  (tracks 1–6)

    wayland.windowManager.hyprland.settings.bind = [
      "SUPER_SHIFT, z, exec, play -n synth 0.1 sine 300 vol 0.3"
      "SUPER_SHIFT, z, submap, reaper"
    ];
    wayland.windowManager.hyprland.extraConfig = ''
        submap = reaper
          bind = , z, exec, play -n synth 0.1 sine 200 vol 0.3
          bind = , z, submap, reset

          # bind = , 1, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/1/mute/toggle
          # bind = , 2, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/2/mute/toggle
          # bind = , 3, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/3/mute/toggle
          # bind = , 4, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/4/mute/toggle
          # bind = , 5, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/5/mute/toggle
          # bind = , 6, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/6/mute/toggle

          # ARM ON (upper row)
          bind = , q, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/1/recarm i 1
          bind = , w, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/2/recarm i 1
          bind = , e, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/3/recarm i 1
          bind = , r, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/4/recarm i 1
          bind = , t, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/5/recarm i 1
          bind = , y, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/6/recarm i 1

          # ARM OFF (lower row)
          bind = , a, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/1/recarm i 0
          bind = , s, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/2/recarm i 0
          bind = , d, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/3/recarm i 0
          bind = , f, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/4/recarm i 0
          bind = , g, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/5/recarm i 0
          bind = , h, exec, ${pkgs.liblo}/bin/oscsend localhost 9800 /track/6/recarm i 0

        submap = reset
    '';

    home.shellAliases = {
      "5reaper" = "taskset -c 4-5 reaper";
    };

    custom.persist = {
      home.directories = [
        ".config/REAPER"
        # ".config/DecentSampler"
        ".vst"
        ".vst3"
        ".lv2"
        ".clap"
        ".local/share/yabridge"
        ".local/share/Plogue"
        "Synapse Audio"
      ];
    };
  };
}

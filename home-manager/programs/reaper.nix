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
      pkgs.reaper-reapack-extension
      pkgs.labwc

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
      pkgs.soundfont-generaluser-gs
      pkgs.soundfont-ydp-grand
      pkgs.noise-repellent
      pkgs.speech-denoiser
      pkgs.mod-distortion
      pkgs.midi-trigger
      pkgs.sfizz-ui
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

    wayland.windowManager.hyprland.extraConfig = ''
      hl.bind("SUPER + SHIFT + z", hl.dsp.exec_cmd("play -n synth 0.1 sine 300 vol 0.3"))
      hl.bind("SUPER + SHIFT + z", hl.dsp.submap("reaper"))
      hl.define_submap("reaper", function()
        hl.bind("z", hl.dsp.exec_cmd("play -n synth 0.1 sine 200 vol 0.3"))
        hl.bind("z", hl.dsp.submap("reset"))
        hl.bind("q", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/1/recarm i 1"))
        hl.bind("w", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/2/recarm i 1"))
        hl.bind("e", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/3/recarm i 1"))
        hl.bind("r", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/4/recarm i 1"))
        hl.bind("t", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/5/recarm i 1"))
        hl.bind("y", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/6/recarm i 1"))
        hl.bind("a", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/1/recarm i 0"))
        hl.bind("s", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/2/recarm i 0"))
        hl.bind("d", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/3/recarm i 0"))
        hl.bind("f", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/4/recarm i 0"))
        hl.bind("g", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/5/recarm i 0"))
        hl.bind("h", hl.dsp.exec_cmd("${pkgs.liblo}/bin/oscsend localhost 9800 /track/6/recarm i 0"))
      end)
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

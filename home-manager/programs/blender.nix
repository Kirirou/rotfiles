{
  config,
  pkgs,
  lib,
  ...
}: {
  config = lib.mkIf config.custom.blender.enable {
    home.packages = [
      # (lib.lowPrio pkgs.blender)
      pkgs.blender
      # (lib.meta.lowPrio pkgs.custom.goo-engine) # TODO! compiled already

      pkgs.unityhub
      pkgs.vrc-get
      pkgs.openseeface
      pkgs.fspy

      # pkgs.gimp
    ];

    custom.persist = {
      home.directories = [
        ".config/blender"
        ".config/unityhub"
        ".config/unity3d"
        ".cache/unityhub"
        "Unity"
      ];
    };
  };
}

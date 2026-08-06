{
  inputs,
  system,
  ...
}:
inputs.devenv.lib.mkShell {
  inherit inputs;

  pkgs = import inputs.nixpkgs {
    inherit system;
  };

  modules = [
    (
      {pkgs, ...}: {
        # devenv configuration
        packages = with pkgs; [
          age
          sops
        ];

        languages.nix.enable = true;
        languages.rust.enable = true;

        pre-commit = {
          hooks = {
            deadnix = {
              enable = false;
              excludes = [
                "generated.nix"
                "templates/.*/flake.nix"
              ];
              settings = {
                edit = true;
              };
            };
            nixfmt = {
              enable = true;
              excludes = ["generated.nix"];
            };
            statix = {
              enable = true;
              excludes = ["generated.nix"];
            };
          };
        };
      }
    )
  ];
}

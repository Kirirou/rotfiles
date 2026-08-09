{
  inputs,
  lib,
  pkgs,
  specialArgs,
  user ? "rot",
  ...
}: let
  mkNixosConfiguration = host:
    lib.nixosSystem {
      inherit pkgs;

      specialArgs =
        specialArgs
        // {
          inherit host user;
          isNixOS = true;
          isLaptop = host == "omen";
        };

      modules = [
        ./${host} # host specific configuration
        ./${host}/hardware.nix # host specific hardware configuration
        ../nixos
        ../modules/nixos
        ../overlays
        inputs.musnix.nixosModules.musnix
        inputs.home-manager.nixosModules.home-manager
        inputs.nix-minecraft.nixosModules.minecraft-servers # MINECRAFT SERVERS
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            extraSpecialArgs =
              specialArgs
              // {
                inherit host user;
                isNixOS = true;
                isLaptop = host == "omen";
              };

            users.${user} = {
              imports = [
                inputs.nix-index-database.homeModules.nix-index
                ./${host}/home.nix # host specific home-manager configuration
                ../home-manager
                ../modules/home-manager
              ];
            };
          };
        }
        # alias for home-manager
        (lib.mkAliasOptionModule ["hm"] [
          "home-manager"
          "users"
          user
        ])
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops # FIXME
      ];
    };
in {
  desktop = mkNixosConfiguration "desktop";
  omen = mkNixosConfiguration "omen";
}

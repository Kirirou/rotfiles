{
  description = "Kyryro's dotfiles, - configuration which is managed via NixOS and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    copyparty.url = "github:9001/copyparty";

    late-sh = {
      url = "github:mpiorowski/late-sh";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    musnix = {
      url = "github:musnix/musnix";
    };

    hyprland.url = "github:hyprwm/hyprland";

    devenv.url = "github:cachix/devenv";

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hyprgrass = {
    #   url = "github:horriblename/hyprgrass";
    # };

    wfetch = {
      url = "github:iynaix/wfetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    focal = {
      url = "github:iynaix/focal";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ie-r = {
      url = "github:miaupaw/ie-r";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

    dzgui.url = "github:jiriks74/dzgui.flake";
  };

  # flake-utils is unnecessary
  # https://ayats.org/blog/no-flake-utils/
  outputs =
    inputs@{ nixpkgs, self, ... }:
    let
      system = "x86_64-linux";
      pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.permittedInsecurePackages = [ "fspy-1.0.3" ];
      };
      pkgs-stable = import inputs.nixpkgs-stable {
        inherit system;
        config.allowUnfree = true;
      };
      lib = import ./lib.nix {
        inherit (nixpkgs) lib;
        inherit pkgs;
        inherit (inputs) home-manager;
      };
      createCommonArgs = system: {
        inherit
          self
          inputs
          nixpkgs
          lib
          pkgs
          pkgs-stable
          system
          ;
        specialArgs = {
          inherit self inputs pkgs-stable;
        };
      };
      commonArgs = createCommonArgs system;
      # call with forAllSystems (commonArgs: function body)
      forAllSystems =
        fn:
        lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: fn (createCommonArgs system));
    in
    {
      nixosConfigurations = import ./hosts/nixos.nix commonArgs;

      homeConfigurations = import ./hosts/hm.nix commonArgs;

      # devenv for working on rotfiles, provides rust environment
      devShells = forAllSystems (pkgs: {
        default = import ./devenv.nix {
          inherit inputs;
          inherit (pkgs) system;
        };
      });

      packages = forAllSystems (pkgs: (import ./packages { inherit pkgs inputs; }));

      # templates for devenvs
      templates = import ./templates;
    };
}

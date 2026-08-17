{
  inputs,
  lib,
  pkgs,
  ...
}: let
  # include generated sources from nvfetcher
  sources = import ./generated.nix {
    inherit
      (pkgs)
      fetchFromGitHub
      fetchurl
      fetchgit
      dockerTools
      ;
  };
in {
  nixpkgs.overlays = [
    (_: prev: {
      # include custom packages
      custom =
        (prev.custom or {})
        // {
          lib = pkgs.callPackage ./lib.nix {inherit (prev) pkgs;};
        }
        // (import ../packages {
          inherit (prev) pkgs;
          inherit inputs;
        });

      # cudaPackages = prev.cudaPackages_12_6;
      # cudaPackages_merged = prev.cudaPackages_12_6;
      # cudaPackages_merged = throw "TRACE: referenced pkgs.cudaPackages_merged";
      # cudaPackages = prev.cudaPackages // {
      #   # optional, in case something grabs a specific attr
      #   cuda_cuobjdump = throw "TRACE: referenced pkgs.cudaPackages.cuda_cuobjdump";
      # };

      opensubdiv = prev.opensubdiv.override {
        cudaSupport = true;
      };
      blender = prev.blender.override {
        cudaSupport = true;
      };

      # cmake = prev.cmake.overrideAttrs (oldAttrs: {
      #   cmakeFlags = oldAttrs.cmakeFlags or [] ++ [
      #     "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
      #   ];
      # });
      
      hyprlock = prev.hyprlock.overrideAttrs (_: sources.hyprlock);

      # add default font to silence null font errors
      lsix = prev.lsix.overrideAttrs (o: {
        postFixup = ''
          substituteInPlace $out/bin/lsix \
            --replace '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
          ${o.postFixup}
        '';
      });

      # nixos-small logo looks like ass
      neofetch = prev.neofetch.overrideAttrs (o: {
        patches = (o.patches or []) ++ [./neofetch-nixos-small.patch];
      });

      # fix nix package count for nitch
      nitch = prev.nitch.overrideAttrs (o: {
        patches = (o.patches or []) ++ [./nitch-nix-pkgs-count.patch];
      });

    })
    inputs.nix-minecraft.overlay
  ];
}

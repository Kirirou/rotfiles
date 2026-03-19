{
  lib,
  pkgs,
  ...
}: {
  options.custom = {
    fonts = {
      regular = lib.mkOption {
        type = lib.types.str;
        default = "Noto Sans Mono CJK JP";
        description = "The font to use for regular text";
      };
      monospace = lib.mkOption {
        type = lib.types.str;
        # default = "JetBrainsMono Nerd Font";
        default = "GohuFont uni11 Nerd Font Mono";
        description = "The font to use for monospace text";
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          font-manager
          monocraft
          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-cjk-serif
          noto-fonts-color-emoji
          corefonts
          liberation_ttf
          liberation-sans-narrow
          vista-fonts
          carlito
          caladea
          gelasio
          kochi-substitute
          kochi-substitute-naga10
          ipafont
          ipaexfont
          migmix
          migu
          hanazono
          ricty
          takao
          jigmo
          rictydiminished-with-firacode
          wqy_zenhei

          (pkgs.stdenvNoCC.mkDerivation {
            name = "minecraft-standard-galactic-alphabet";
            src = ./minecraft-standard-galactic-alphabet.otf.zip;
            nativeBuildInputs = [ pkgs.unzip ];
            sourceRoot = ".";
            installPhase = ''
              mkdir -p $out/share/fonts/opentype
              cp *.otf $out/share/fonts/opentype/
            '';
          })

        ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
        description = "The packages to install for the fonts";
      };
    };
  };
}

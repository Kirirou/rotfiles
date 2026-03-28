{lib, ...}: {
  options.custom.shortcuts = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {
      h = "~";
      rots = "~/pr/rotfiles";
      dots = "~/pr/dotfiles";
      cfg = "~/.config";
      pr = "~/pr";
      rustpr = "~/pr/rustpr/ln/";
      PC = "~/Pictures";
      Ps = "~/Pictures/Screenshots";
      Pw = "~/Pictures/Wallpapers";
      dw = "~/Downloads";
      docs = "~/Documents";
      wdd = "/md/wdc-data";
      stsea = "/md/stsea-okii";
      wdsmall = "/md/wdc-data/_SMALL";
      wdanime = "/md/wdc-data/_SMALL/_ANIME/";
      wdfilm = "/md/wdc-data/_SMALL/_FILM/";
      wdimg = "/md/wdc-data/_SMALL/_IMAGE/";
      wdmain = "/md/wdc-data/_MAIN/";
      wdnt = "/md/wdc-data/_MAIN/_NT_STUDIO";
      wdzirka = "/md/wdc-data/_MAIN/_NT_STUDIO/_ZIRKA";
      zirkasc = "/md/wdc-data/_MAIN/_NT_STUDIO/_ZIRKA/scenario-zirka";
      papers = "/md/wdc-data/Documents/papers";
      mdkorobka = "/md/wdc-data/_FARMTASKER";
      curr = "~/_CURRENT";
    };
    description = "Shortcuts for navigating across multiple terminal programs.";
  };
}

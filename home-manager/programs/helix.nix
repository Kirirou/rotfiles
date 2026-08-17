{
  config,
  lib,
  pkgs,
  ...
}:
let
  tex = pkgs.texliveSmall.withPackages (ps: with ps; [
    dvisvgm dvipng
    wrapfig amsmath ulem hyperref capt-of tex-gyre cyrillic
  ]);
in
{
  config = lib.mkIf config.custom.helix.enable {
    home.packages = [
      pkgs.lldb
      pkgs.clang-tools
      tex
      # pkgs.texlive.combined.scheme-full
      pkgs.texlivePackages.tex-gyre
      pkgs.texlab
      pkgs.pandoc
      pkgs.yamlfmt
      pkgs.yaml-language-server
      pkgs.bash-language-server
    ];
    programs.helix = {
      enable = true;
      defaultEditor = config.custom.shell.defaultEditor == "hx";
      themes = {
        mtr = {
          # "inherits" = "heisenberg";
          # "inherits" = "curzon";
          # "inherits" = "mellow";
          "inherits" = "ferra";
          # "inherits" = "vim_dark_high_contrast";
          # "inherits" = "catppuccin_mocha";
          # "inherits" = "catppuccin_latte";
          "ui.background" = {
            fg = "none";
          };
        };
      };
      languages = {
        language = [
          {
            name = "yaml";
            formatter = { command = "${pkgs.yamlfmt}/bin/yamlfmt"; args = [ "-in" ];};
            language-servers = [ "yaml-language-server" ];
          }
        ];
        language-server.yaml-language-server.command = "${pkgs.yaml-language-server}/bin/yaml-language-server";
        language-server.rust-analyzer.command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        language-server.rust-analyzer.config = {
          procMacro = {
            ignored = {
              # leptos_macro = [ "server" "component" ]; // makes huge red warning...
            };
          };
          diagnostics.disabled = [
            "inactive-code"
            "unlinked-file"
          ];
        };
      };
      settings = {
        theme = "mtr";
        editor = {
          lsp.display-messages = true;
          lsp.display-inlay-hints = true;
          statusline = {
            center = [ "file-absolute-path" ];
          };
          true-color = true;
          line-number = "relative";
          mouse = true;
          rulers = [ 0 ];
          bufferline = "always";
        };
        keys.select = {
          X = [
            "extend_line_up"
            "extend_to_line_bounds"
          ];
          "Ч" = [
            "extend_line_up"
            "extend_to_line_bounds"
          ];
          A-x = "extend_to_line_bounds";
          "A-ч" = [
            "extend_to_line_bounds"
          ];
          C-y = "yank_to_clipboard";
          "C-н" = "yank_to_clipboard";
        };
        keys.normal = lib.mkForce {
          X = [
            "extend_line_up"
            "extend_to_line_bounds"
          ];
          A-x = "extend_to_line_bounds";
          C-p = [
            "move_line_up"
            "scroll_up"
          ];
          C-n = [
            "move_line_down"
            "scroll_down"
          ];
          C-y = "yank_to_clipboard";
          esc = [
            "collapse_selection"
            "keep_primary_selection"
          ]; # FIXME
        };
        editor.cursor-shape = {
          insert = "bar";
          # normal = "block";
          select = "underline";
        };
        editor.file-picker = {
          hidden = false;
        };
      };
    };
  };
}

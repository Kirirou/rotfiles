{
  config,
  lib,
  pkgs,
  ...
}:
let
  tex = (pkgs.texlive.combine {
    inherit (pkgs.texlive) scheme-full
      dvisvgm dvipng # for preview and export as html
      wrapfig amsmath ulem hyperref capt-of tex-gyre cyrillic;
      # (setq org-latex-compiler "lualatex")
      # (setq org-preview-latex-default-process 'dvisvgm)
  });
in
{
  config = lib.mkIf config.custom.helix.enable {
    home.packages = [
      pkgs.lldb
      pkgs.clang-tools
      tex
      # pkgs.texlive.combined.scheme-full
      pkgs.texlivePackages.cyrillic
      pkgs.texlivePackages.tex-gyre
      pkgs.texlab
      pkgs.pandoc
      pkgs.yamlfmt
      pkgs.yaml-language-server
      pkgs.bash-language-server

      (pkgs.writeShellScriptBin "latex-watch" ''
        if [ -z "$1" ]; then
          echo "Usage: latex-watch <file.tex>"
          exit 1
        fi

        FILE="$1"
        PDF="$(basename "$FILE" .tex).pdf"
        CLASS="org.pwmt.zathura"

        while true; do
          ${pkgs.inotify-tools}/bin/inotifywait -qq -e close_write "$FILE"

          ${pkgs.procps}/bin/pkill -f "zathura.*$PDF"

          ${pkgs.texlive.combined.scheme-small}/bin/pdflatex -interaction=nonstopmode "$FILE" >/dev/null

          ${pkgs.zathura}/bin/zathura "$PDF" &

          sleep 0.4

          ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow "class:($CLASS)"
          ${pkgs.hyprland}/bin/hyprctl dispatch setfloating active
          ${pkgs.hyprland}/bin/hyprctl dispatch resizeactive exact 1000 1200
          ${pkgs.hyprland}/bin/hyprctl dispatch moveactive exact 2060 120
        done
      '')
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
        keys.normal = {
          # until fixed ISSUE: https://github.com/helix-editor/helix/issues/10389
          # Workaround for ukrainian lagnuage key remap
          # українська мапа клавіатури:

          # перший ряд
          "й" = [ "replay_macro" ]; # q
          "ц" = [ "move_next_word_start" ]; # w
          "у" = [ "move_next_word_end" ]; # e
          "к" = [ "replace" ]; # r
          "е" = [ "find_till_char" ]; # t
          "н" = [ "yank_to_clipboard" ]; # y
          "г" = [ "undo" ]; "C-г" = [ "page_cursor_half_up" ]; # u
          "ш" = [ "insert_mode" ]; "C-ш" = [ "jump_forward" ]; # i
          "щ" = [ "open_below" ]; "C-щ" = [ "jump_backward" ]; # o
          "з" = [ "paste_clipboard_after" ]; # p
          "х" = [ ]; # @
          "ї" = [ ]; # [

          "Й" = [ "record_macro" ]; # Q
          "Ц" = [ "move_next_long_word_start" ]; # W
          "У" = [ ]; # E
          "К" = [ "replace_selections_with_clipboard" ]; # R
          "Е" = [ "till_prev_char" ]; # T
          "Н" = [ "yank_main_selection_to_clipboard" ]; # Y
          "Г" = [ "redo" ]; # U
          "Ш" = [ "insert_at_line_start" ]; # I
          "Щ" = [ "open_above" ]; # O
          "З" = [ "paste_clipboard_before" ]; # P
          # "Х" = [ ]; # `
          # "Ї" = [ ]; # {

          # другий ряд 
          "ф" = [ "append_mode" ]; # a
          "і" = [ "select_regex" ]; "C-і" = [ "save_selection" ]; "A-і" = [ "split_selection_on_newline" ]; # s
          "в" = [ "delete_selection" ]; "C-в" = [ "page_cursor_half_down" ]; # d
          "а" = [ "find_next_char" ]; "C-а" = [ "page_down" ]; # f
          "п" = [ ]; # g
          "р" = [ "move_char_left" ]; # h
          "о" = [ "move_visual_line_down" ]; # j
          "л" = [ "move_visual_line_up" ]; # k
          "д" = [ "move_char_right" ]; # l
          # "ж" = [ ]; # ;
          # "є" = [ ]; # : # important to leave unbinded to not confuse layouts
          # "ґ" = [ ]; # ]

          "Ф" = [ "insert_at_line_end" ]; # A
          "І" = [ "split_selection" ]; # S
          # "В" = [ ]; # D
          "А" = [ "find_prev_char" ]; # F
          "П" = [ "goto_line" ]; # G
          # "Р" = [ ]; # H
          "О" = [ "join_selections" ]; # J
          "Л" = [ "keep_selections" ]; # K
          # "Д" = [ ]; # L
          # "Ж" = [ ]; # +
          # "Є" = [ ]; # *
          # "Ґ" = [ ]; # }

          # третій ряд
          # "я" = [ ]; # z
          "ч" = [ "extend_line_below" ]; # x
          "с" = [ "change_selection" ]; "A-с" = [ "change_selection_noyank" ]; # c
          "м" = [ "select_mode" ]; # v
          "и" = [ "move_prev_word_start" ]; "C-и" = [ "page_up" ]; # b
          "т" = [ "search_next" ]; # n
          "ь" = [ ]; # m
          "б" = [ ]; # ,
          "ю" = [ ]; # .
          "." = [ "global_search" ]; # /

          # "Я" = [ ]; # Z
          "Ч" = [ "extend_to_line_bounds" ]; # X
          "С" = [ ]; # "М" = []; # V
          "И" = [ "move_prev_long_word_start" ]; # B
          "Т" = [ "search_prev" ]; # N
          "Ь" = [ ]; # M
          "Б" = [ ]; # <
          "Ю" = [ ]; # >
          "," = [ ]; # ?

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

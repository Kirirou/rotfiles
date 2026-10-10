{ pkgs, ... }:
{
  imports = [
    ./bash.nix
    ./btop.nix
    ./cava.nix
    ./direnv.nix
    ./eza.nix
    ./fish.nix
    ./git.nix
    ./nix.nix
    ./rice.nix
    ./rust.nix
    ./shell.nix
    ./starship.nix
    ./tmux.nix
    ./yazi.nix
  ];

  home.packages = with pkgs; [
    dysk # better disk info
    fselect
    fd # better find
    fx # terminal json viewer and processor
    htop
    dust # better du
    dua
    just
    # mask
    jq
    htmlq
    sd # better sed
    libnotify
    ugrep
    file
    fdupes
    b3sum
    tldr
    hwatch
    entr
    ent
    nethogs
    mprocs
    presenterm
    # coreutils-full
    uutils-coreutils
    util-linux
    pciutils
    ffmpeg
    woeusb
    fio
    qrencode
    lshw
    kdiff3
    krename
    cpulimit
    gnuplot
    llvmPackages.bintools-unwrapped
    linuxConsoleTools
    patchelf
    daemonize
    lftp

    cmus
    devenv
    claude-code

    git-filter-repo
    stripe-cli

    typora # md viewer
    marksman # mv lsp
    vscode-langservers-extracted # lldb-vscode
    # javascript-typescript-langserver # web js
    typescript-language-server
    yaml-language-server # yaml lsp
    taplo # toml lsp
  ];

  programs = {
    bat.enable = true;

    fzf = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };

    nix-index.enable = true;

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
    };
  };

  custom.persist = {
    home.directories = [
      ".local/share/zoxide"
      ".config/Typora"
      ".cache/tealdear"
      ".claude"
    ];
    # Claude Code's login/session token - lives directly in $HOME, not
    # inside .claude/, so it was falling through the persist allowlist
    # and getting wiped by impermanence every reboot, forcing a browser
    # re-login each time.
    home.files = [
      ".claude.json"
    ];
  };

  custom.shell.packages.persist-adopt = pkgs.writeShellApplication {
    name = "persist-adopt";
    text = ''
      # Moves an existing file/directory under $HOME into its /persist
      # location, so it's ready before you add the path to custom.persist
      # and rebuild. impermanence's own mount-file.bash refuses to bind-
      # mount over a path that already has content at the live location -
      # by design, so it never has to guess which copy wins - so a plain
      # `cp` into persist (leaving the original in place) just moves the
      # conflict to the next rebuild instead of fixing it. This does the
      # move, not a copy, so there's nothing left at the live path for
      # that guard to trip on.
      if [ $# -ne 1 ]; then
        echo "usage: persist-adopt <path relative to \$HOME>" >&2
        exit 1
      fi

      rel="$1"
      live="$HOME/$rel"
      target="/persist$HOME/$rel"

      if [ -e "$target" ]; then
        echo "already present at $target - nothing to adopt" >&2
        exit 1
      fi
      if [ ! -e "$live" ]; then
        echo "nothing at $live to adopt" >&2
        exit 1
      fi

      mkdir -p "$(dirname "$target")"
      mv -n "$live" "$target"
      echo "moved $live -> $target"
      echo "now add \"$rel\" to custom.persist.home.{files,directories} and rebuild"
    '';
  };
}

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

    cmus
    devenv

    git-filter-repo
    stripe-cli
    # nodePackages.vercel

    typora # md viewer
    marksman # mv lsp
    vscode-langservers-extracted # lldb-vscode
    # javascript-typescript-langserver # web js
    nodePackages.typescript-language-server
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
    ];
  };
}

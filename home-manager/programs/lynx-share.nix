{ pkgs, ... }:
{
  home.packages = [ pkgs.custom.lynx-share ];

  custom.persist = {
    home.directories = [ ".config/LYNX" ];
  };
}

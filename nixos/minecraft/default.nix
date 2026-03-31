{
  config,
  lib,
  user,
  pkgs,
  ...
}: {
  imports = [
    ./minecraft-bedrock-server.nix
    ./minecraft-java-server-fabricer.nix
  ];
  config = {
    users.users.${user}.extraGroups = ["minecraft"];
    environment.systemPackages = with pkgs; [
      packwiz
      rcon
    ];
    custom.persist.root.directories = [
      "/srv"
    ];
  };
}

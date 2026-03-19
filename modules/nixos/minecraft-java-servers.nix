{
  lib,
  pkgs,
  ...
}:
with lib; let
  mkOpt = type: default:
    mkOption {inherit type default;};

  mkOpt' = type: default: description:
    mkOption {inherit type default description;};
in {
  # MINECRAFT
  options.custom.minecraft.enable = lib.mkEnableOption "minecraft" // {
    default = false;
  };
  options.custom.services.minecraft-java-servers = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable the whole Minecraft Java Servers thing.
      '';
    };
    environmentFile = mkOpt' (lib.types.nullOr lib.types.path) null ''
      File consisting of lines in the form varname=value to define environment
      variables for the minecraft servers.

      Secrets (database passwords, secret keys, etc.) can be provided to server
      files without adding them to the Nix store by defining them in the
      environment file and referring to them in option
      <option>services.minecraft-servers.servers.<name>.files</option> with the
      syntax @varname@.
    '';
    fabricer = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.fabricServers.fabric-1_21_1;
        defaultText = "pkgs.fabricServers.fabric-1_21_4";
        description = "Version of minecraft to run.";
      };

      do-run = lib.mkEnableOption "Stop minecraft server?" // {default = true;};
      autoStart = lib.mkEnableOption "Auto start minecraft server on boot?" // {default = true;};
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enable Fabric Server
        '';
      };
      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/srv/minecraft-java-server-fabricer";
        description = ''
          Directory to store Minecraft Bedrock database and other state/data files.
        '';
      };
      jvmOpts = mkOpt' (types.separatedString " ") "-Xmx22G -Xms22G" "JVM options for this server.";
      # example = "-Xms4096M -Xmx4096M -XX:+UseG1GC -XX:+CMSIncrementalPacing -XX:+CMSClassUnloadingEnabled -XX:ParallelGCThreads=2 -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10";

      tfcConfigFile = lib.mkOption {
        type = lib.types.str;
        default = ''
          [general]
          	#
          	# If the TFC world preset 'tfc:overworld' should be set as the default world generation when creating a new world.
          	defaultWorldPreset = "tfc:overworld"

          [calendar]
          	#
          	# The number of days in a month, for newly created worlds.
          	# This can be modified in existing worlds using the /time command
          	#Range: > 1
          	# defaultMonthLength = 8 # DEFAULT IS 8
          	defaultMonthLength = 31
          	#
          	# The start date for newly created worlds, in a number of ticks, for newly created worlds
          	# This represents a number of days offset from January 1, 1000
          	# The default is (5 * daysInMonth) = 40, which starts at June 1, 1000 (with the default daysInMonth = 8)
          	#Range: > -1
          	defaultCalendarStartDay = 40

          [debug]
          	#
          	# Enables a series of network fail-safes that are used to debug network connections between client and servers.
          	# Important: this MUST BE THE SAME as what the server has set, otherwise you are liable to see even stranger errors.
          	enableNetworkDebugging = false
          	#
          	# If enabled, TFC will validate that certain pieces of reloadable data fit the conditions we expect, for example heating recipes having heatable items. It will error or warn in the log if these conditions are not met.
          	enableDatapackTests = false
        '';
      };

      # Whitelisted players,
      # only has an effect when services.minecraft-server.declarative is true
      # and the whitelist is enabled via by setting serverProperties.white-list to true.
      # This is a mapping from Minecraft usernames to UUIDs.
      # You can use https://mcuuid.net/ to get a Minecraft UUID for a username.
      whitelist = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "Arbitrary whitelist for the Minecraft Java Server.";
        example = {
          username1 = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
          username2 = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy";
        };
      };

      opsJson = lib.mkOption {
        # type = with lib.types; listOf attrs;
        type = lib.types.listOf (lib.types.submodule { freeformType = (pkgs.formats.json {  }).type; });
        default = [];
        description = ''
          A list of operators for the Minecraft server. Each operator is represented by an
          attribute set containing the following keys:

          - `uuid` (string): The unique identifier for the player.
          - `name` (string): The name of the player.
          - `level` (integer): The operator level (1-4).
          - `bypassesPlayerLimit` (boolean): Whether the player bypasses the server's player limit.
        
          Example value:
          [
            {
              uuid = "2cbb65e9-088b-48d8-be9e-0f7b4d0c0b62";
              name = "sqwq";
              level = 4;
              bypassesPlayerLimit = true;
            }
            {
              uuid = "12b5c603-8037-4c03-92e7-00b9cfcfd82a";
              name = "playername";
              level = 1;
              bypassesPlayerLimit = false;
            }
            # Add more operators as needed
          ]
        '';
      };

      serverProperties = lib.mkOption {
        type = with lib.types; attrsOf (oneOf [bool int str]);
        default = {
          #Minecraft server properties
          enable-jmx-monitoring = false;
          "rcon.port" = 25585;
          level-seed = "";
          gamemode = "survival";
          enable-command-block = false;
          enable-query = false;
          generator-settings = "{}";
          enforce-secure-profile = true;
          level-name = "Java level";
          motd = "Nixos Minecraft Server";
          "query.port" = 25563;
          pvp = true;
          generate-structures = true;
          max-chained-neighbor-updates = 1000000;
          difficulty = "easy";
          network-compression-threshold = 256;
          max-tick-time = 60000;
          require-resource-pack = false;
          use-native-transport = true;
          max-players = 20;
          online-mode = true;
          enable-status = true;
          allow-flight = false;
          initial-disabled-packs = "";
          broadcast-rcon-to-ops = true;
          view-distance = 10;
          server-ip = "";
          resource-pack-prompt = "";
          allow-nether = true;
          server-port = 25564;
          enable-rcon = false;
          sync-chunk-writes = true;
          op-permission-level = 4;
          prevent-proxy-connections = false;
          hide-online-players = false;
          resource-pack = "";
          entity-broadcast-range-percentage = 100;
          simulation-distance = 10;
          "rcon.password" = "";
          player-idle-timeout = 0;
          force-gamemode = false;
          rate-limit = 0;
          hardcore = false;
          white-list = false;
          broadcast-console-to-ops = true;
          spawn-npcs = true;
          spawn-animals = true;
          log-ips = true;
          function-permission-level = 2;
          initial-enabled-packs = "vanilla";
          level-type = "minecraft\:normal";
          text-filtering-config = "";
          spawn-monsters = true;
          enforce-whitelist = false;
          spawn-protection = 16;
          resource-pack-sha1 = "";
          max-world-size = 29999984;
        };
        description = ''
          Minecraft Java server properties for the server.properties file.
        '';
      };
    }; # Minecraft Fabric Server
  };
}

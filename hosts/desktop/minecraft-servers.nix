{pkgs, ...}: {
  custom = {
    minecraft.enable = false;
    services.minecraft-bedrock-server = {
      enable = false; # can't fetch source of bedrock server
      do-run = false;
      # package = pkgs.custom.minecraft-bedrock-server;
      dataDir = "/srv/minecraft-bedrock-server";
      permissions = [
        # {
        #   permission = "operator";
        #   pfid = "6cf9edda1be490d6";
        # }
        # {
        #   permission = "operator";
        #   xuid = "2535460878389100";
        # }
      ];
      serverProperties = {
        server-name = "Dedicated Rot Server";
        gamemode = "survival";
        difficulty = "hard";
        allow-cheats = true;
        max-players = 10;
        online-mode = true;
        white-list = false;
        server-ip = "";
        server-port = 25575;
        emit-server-telemetry = true;
        view-distance = 32;
        tick-distance = 4;
        player-idle-timeout = 30;
        max-threads = 4;
        level-name = "Jungle Island";
        level-seed = "0";
        default-player-permission-level = "member";
        texturepack-required = false;
        content-log-file-enabled = false;
        compression-threshold = 1;
        server-authoritative-movement = "server-auth";
        player-movement-score-threshold = 20;
        player-movement-distance-threshold = "0.3";
        player-movement-duration-threshold-in-ms = 500;
        correct-player-movement = false;
      };
    };
    services.minecraft-java-servers.fabricer = {
      enable = true;
      do-run = true;
      autoStart = true;
      dataDir = "/srv/minecraft-java-server-fabricer";
      jvmOpts = "-Xms12g -Xmx16g -XX:+UseG1GC -XX:ParallelGCThreads=4";
      opsJson = [
        {
          uuid = "2cbb65e9-088b-48d8-be9e-0f7b4d0c0b62";
          name = "kyryro";
          level = 4;
          bypassesPlayerLimit = false;
        }
      ];
      serverProperties = {
        enable-jmx-monitoring = false;
        "rcon.port" = 2526;
        server-port = 25565;
        level-seed = "";
        gamemode = "survival";
        enable-command-block = true;
        enable-query = false;
        generator-settings = "{}";
        enforce-secure-profile = true;
        level-name = "fabricer_world";
        motd = "Реалістичний Майнкрафт модпак Сервер";
        "query.port" = 25565;
        pvp = false;
        generate-structures = true;
        max-chained-neighbor-updates = 1000000;
        difficulty = "hard";
        network-compression-threshold = 256;
        max-tick-time = 60000;
        require-resource-pack = false;
        use-native-transport = true;
        max-players = 3;
        online-mode = true;
        enable-status = true;
        allow-flight = true;
        initial-disabled-packs = "";
        broadcast-rcon-to-ops = true;
        view-distance = 64;
        server-ip = "192.168.1.101";
        resource-pack-prompt = "";
        allow-nether = false;
        enable-rcon = true;
        sync-chunk-writes = true;
        op-permission-level = 4;
        prevent-proxy-connections = false;
        hide-online-players = false;
        resource-pack = "";
        entity-broadcast-range-percentage = 100;
        simulation-distance = 10;
        "rcon.password" = "ASDsss";
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
        level-type = "bigglobe\:bigglobe";
        text-filtering-config = "";
        spawn-monsters = true;
        enforce-whitelist = false;
        spawn-protection = 16;
        resource-pack-sha1 = "";
        max-world-size = 29999984;
      };
    };
  };
}

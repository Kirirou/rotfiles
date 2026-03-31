{
  config,
  user,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.static-web-server;
  domain-name = "rotteegher.ddns.net";
  domain-name2 = "local.farmtasker.au";
  path-to-serve = "/md/wdc-data/_SMALL/_ONLINE_TANK";
in lib.mkMerge [
{
  security.acme = {
    acceptTerms = true;
    defaults.email = "souonchouryuu@proton.me";
  };

  # Now we need to open port 80 for the ACME challenge and port 443 for SWS itself
  networking.firewall.allowedTCPPorts = [ 80 443 3210 3211 ];
  networking.firewall.allowedUDPPorts = [ 80 443 3210 3211 ];

  environment.systemPackages = [ pkgs.copyparty ];

  services.onedrive.enable = true;

  services.copyparty = {
    enable = false;
    # directly maps to values in the [global] section of the copyparty config.
    # see `copyparty --help` for available options
    settings = {
      ban-404 = false;
      ban-403 = false;
      i = "0.0.0.0";
      # use lists to set multiple values
      p = [ 3210 3211 ];
      # use booleans to set binary flags
      no-reload = true;
      # using 'false' will do nothing and omit the value when generating a config
      ignored-flag = false;

      shr = "/shares";
      shr-rt = "1440";  # keep expired share record for 1 day

      no-robots = true;
      rproxy = 1;
      xff-hdr = "x-real-ip";
      xff-src = "127.0.0.1,::1";
      acao = [                          # 💬 valid CORS origins for browser calls
        "https://192.168.12.1"
        "https://192.168.1.101"
        "https://127.0.0.1"
        "https://localhost"
        "https://rotteegher.ddns.net"
        "https://local.farmtasker.au"

        "http://192.168.12.1"
        "http://192.168.1.101"
        "http://127.0.0.1"
        "http://localhost"
        "http://rotteegher.ddns.net"
        "http://local.farmtasker.au"
      ];
      acam = [ "GET" "HEAD" "POST" "PUT" "DELETE" "OPTIONS" ];  # HTTP methods allowed cross-origin
    };


    # create a volume
    volumes = {
      "/guest" = {
        path = "/md/wdc-data/_ONLINE_TANK/guest";
        # see `copyparty --help-accounts` for available options
        access = {
          rwmd = "olesia,guest";
          # user "${user}" gets admin access
          A = [ user ];
        };
        # see `copyparty --help-flags` for available options
        flags = {
          # "fk" enables filekeys (necessary for upget permission) (4 chars long)
          fk = 4;
          # scan for new files every 60sec
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          d2t = true;
          # skips hashing file contents if path matches *.iso
          nohash = "\.iso$";
        };
      };
      "/media" = {
        path = "/md/wdc-data/_ONLINE_TANK/media";
        # see `copyparty --help-accounts` for available options
        access = {
          rwm = "olesia,margo";
          # user "${user}" gets admin access
          A = [ user ];
        };
        # see `copyparty --help-flags` for available options
        flags = {
          # "fk" enables filekeys (necessary for upget permission) (4 chars long)
          fk = 4;
          # scan for new files every 60sec
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          d2t = true;
          # skips hashing file contents if path matches *.iso
          nohash = "\.iso$";
        };
      };
      "/family" = {
        path = "/md/wdc-data/_ONLINE_TANK/family";
        # see `copyparty --help-accounts` for available options
        access = {
          rwmd = "olesia";
          # user "${user}" gets admin access
          A = [ user ];
        };
        # see `copyparty --help-flags` for available options
        flags = {
          # "fk" enables filekeys (necessary for upget permission) (4 chars long)
          fk = 4;
          # scan for new files every 60sec
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          d2t = true;
          # skips hashing file contents if path matches *.iso
          nohash = "\.iso$";
        };
      };
      "/md" = {
        path = "/md";
        # see `copyparty --help-accounts` for available options
        access = {
          # user "${user}" gets admin access
          A = [ user ];
        };
        # see `copyparty --help-flags` for available options
        flags = {
          # "fk" enables filekeys (necessary for upget permission) (4 chars long)
          fk = 4;
          # scan for new files every 60sec
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          d2t = true;
          # skips hashing file contents if path matches *.iso
          nohash = "\.iso$";
        };
      };
      "/home" = {
        path = "/persist/home/rot";
        # see `copyparty --help-accounts` for available options
        access = {
          # user "${user}" gets admin access
          A = [ user ];
        };
        # see `copyparty --help-flags` for available options
        flags = {
          # "fk" enables filekeys (necessary for upget permission) (4 chars long)
          fk = 4;
          # scan for new files every 60sec
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          d2t = true;
          noidx = "^\\.[^/]+(/|$)";
          nohash = "^\\.[^/]+(/|$)";
        };
      };
    };
    # you may increase the open file limit for the process
    openFilesLimit = 8192;
  };

  custom.persist = {
    root.directories = ["/var/lib/acme" "/var/lib/filebrowser"];
  };
}
(lib.mkIf config.custom.sops.enable {
      sops.secrets.sws_admin.owner = "copyparty";
      sops.secrets.sws_admin.group = "copyparty";

      sops.secrets.sws_guest.owner ="copyparty";
      sops.secrets.sws_guest.group ="copyparty";

      sops.secrets.sws_olesia.owner ="copyparty";
      sops.secrets.sws_olesia.group ="copyparty";

      sops.secrets.sws_margo.owner ="copyparty";
      sops.secrets.sws_margo.group ="copyparty";
      
      services.copyparty = {
        # create users
        accounts = {
          # specify the account name as the key
          ${user}.passwordFile = config.sops.secrets.sws_admin.path;
          guest.passwordFile = config.sops.secrets.sws_guest.path;

          olesia.passwordFile = config.sops.secrets.sws_olesia.path;

          margo.passwordFile = config.sops.secrets.sws_margo.path;
        };
      };
  })
]

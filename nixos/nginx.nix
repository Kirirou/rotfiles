{ config, lib, pkgs, user, ...}:
lib.mkMerge [  
(lib.mkIf config.custom.nginx.enable {
  security.acme = {
    acceptTerms = true;
    defaults.email = "souonchouryuu@proton.me";
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "192.168.1.101" = {
        listen = [
          { addr = "0.0.0.0"; port = 80;}
        ];
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:3210";
          };
        };
      };

      "localhost" = {
        listen = [
          { addr = "0.0.0.0"; port = 80;}
        ];
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:3210";
          };
        };
      };

      # "nextcloud.farmtasker.au" = {
      #   listen = [
      #     # { addr = "0.0.0.0"; port = 9999; }
      #     { addr = "0.0.0.0"; port = 80; }
      #   ];
      #   locations = {
      #     "/" = {
      #       proxyPass = "http://127.0.0.1";
      #     };
      #   };
      # };

      "local.farmtasker.au" = {
        enableACME = true;
        extraConfig = ''
          # real client IP forwarding
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;

          # upload tuning
          client_max_body_size 0;
          proxy_request_buffering off;
          proxy_http_version 1.1;
        '';
        forceSSL = true;
          sslCertificate = "/var/lib/acme/local.farmtasker.au/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/local.farmtasker.au/key.pem";
          sslTrustedCertificate = "/var/lib/acme/local.farmtasker.au/chain.pem";
        listen = [
          { addr = "0.0.0.0"; port = 443; ssl = true;}
          { addr = "0.0.0.0"; port = 80;}
        ];
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:3210";
          };
        };
      };

      "jellyfin.farmtasker.au" = {
        enableACME = true;
        extraConfig = ''
          # real client IP forwarding
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $remote_addr;
          proxy_set_header X-Forwarded-Proto $scheme;

          # upload tuning
          client_max_body_size 0;
          proxy_request_buffering off;
          proxy_http_version 1.1;
        '';
        forceSSL = true;
          sslCertificate = "/var/lib/acme/jellyfin.farmtasker.au/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/jellyfin.farmtasker.au/key.pem";
          sslTrustedCertificate = "/var/lib/acme/jellyfin.farmtasker.au/chain.pem";
        listen = [
          { addr = "0.0.0.0"; port = 443; ssl = true;}
          { addr = "0.0.0.0"; port = 80;}
        ];
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:8096";
          };
        };
      };

      "rotteegher.ddns.net" = {
        enableACME = true;
        serverName = "rotteegher.ddns.net";
        forceSSL = true;
          sslCertificate = "/var/lib/acme/rotteegher.ddns.net/fullchain.pem";
          sslCertificateKey = "/var/lib/acme/rotteegher.ddns.net/key.pem";
          sslTrustedCertificate = "/var/lib/acme/rotteegher.ddns.net/chain.pem";
        listen = [
          { addr = "0.0.0.0"; port = 443; ssl = true;}
          { addr = "0.0.0.0"; port = 80;}
        ];
        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:3210";
            extraConfig = ''
              client_max_body_size 0;      # or 0 to disable the limit entirely
              proxy_request_buffering off;    # stream the body, helpful for big uploads/streams    
            '';
          };
          "/api" = {
            proxyPass = "http://127.0.0.1:11434";
            extraConfig = ''
              client_max_body_size 0;      # or 0 to disable the limit entirely
              proxy_request_buffering off;    # stream the body, helpful for big uploads/streams    

              proxy_hide_header Access-Control-Allow-Origin;

              # neutralize preflight noise to upstream
              proxy_set_header Origin "";
              proxy_set_header Access-Control-Request-Method "";
              proxy_set_header Access-Control-Request-Headers "";

              # *** key line ***
              proxy_set_header Host $host;

              # optional: don’t leak real client IP to Ollama
              # (not strictly required—Host is the big one)
              proxy_set_header X-Real-IP 192.168.1.1;
              proxy_set_header X-Forwarded-For 192.168.1.1;
              proxy_set_header X-Forwarded-Proto http;

              add_header Access-Control-Allow-Origin * always;
              add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
              add_header Access-Control-Allow-Headers "authorization,content-type" always;
              if ($request_method = OPTIONS) { return 204; }

              proxy_http_version 1.1;
              proxy_read_timeout 1h;
            '';
          };
          "/v1" = {
            proxyPass = "http://127.0.0.1:11434";
            extraConfig = ''
              client_max_body_size 0;      # or 0 to disable the limit entirely
              proxy_request_buffering off;    # stream the body, helpful for big uploads/streams    

              proxy_hide_header Access-Control-Allow-Origin;

              # neutralize preflight noise to upstream
              proxy_set_header Origin "";
              proxy_set_header Access-Control-Request-Method "";
              proxy_set_header Access-Control-Request-Headers "";

              # *** key line ***
              proxy_set_header Host $host;

              # optional: don’t leak real client IP to Ollama
              # (not strictly required—Host is the big one)
              proxy_set_header X-Real-IP 192.168.1.1;
              proxy_set_header X-Forwarded-For 192.168.1.1;
              proxy_set_header X-Forwarded-Proto http;

              add_header Access-Control-Allow-Origin * always;
              add_header Access-Control-Allow-Methods "GET, POST, PUT, DELETE, OPTIONS" always;
              add_header Access-Control-Allow-Headers "authorization,content-type" always;
              if ($request_method = OPTIONS) { return 204; }

              proxy_http_version 1.1;
              proxy_read_timeout 1h;
            '';
          };
        };
      };
    };
  };
  networking.firewall.allowedTCPPorts = [ 9999 80 443 3000 2222 11434 11435 21434 ];
  networking.firewall.allowedUDPPorts = [ 9999 80 443 3000 2222 11434 11435 21434 ];
})
(lib.mkIf (config.custom.sops.enable && config.custom.llm.enable) {
  sops.secrets.ollama_apikey = {
    owner = "nginx";
    group = "nginx";
    mode = "0440";
  };
  sops.secrets.ollama_bearer = {
    owner = "nginx";
    group = "nginx";
    mode = "0440";
  };
  # services.nginx.virtualHosts."rotteegher.ddns.net".locations = {
  #   "/api".extraConfig = ''
  #       auth_basic "Ollama API";
  #       auth_basic_user_file ${config.sops.secrets.ollama_apikey.path};
  #   '';
  #   "/v1".extraConfig = ''        
  #       auth_basic "Ollama API";
  #       auth_basic_user_file ${config.sops.secrets.ollama_apikey.path};
  #   '';
  # };  
})
]

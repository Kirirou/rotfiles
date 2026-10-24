{
  config,
  lib,
  pkgs,
  user,
  ...
}:
let 
  additionalPackages = [
    pkgs.sycl-info
    pkgs.adaptivecpp
    pkgs.level-zero
    # pkgs.mkl
    pkgs.vpl-gpu-rt
    pkgs.intel-compute-runtime.drivers
    pkgs.intel-compute-runtime.out
    pkgs.intel-gpu-tools
    pkgs.intel-media-driver
    pkgs.intel-gmmlib
    pkgs.intel-vaapi-driver
    pkgs.vaapi-intel-hybrid
    pkgs.intel-gmmlib
    pkgs.intel-ocl
    pkgs.libgcc.libgcc
    pkgs.libgcc.lib
    pkgs.libgcc.out
    pkgs.libva
    pkgs.libva-utils
    pkgs.libva-vdpau-driver

    pkgs.cudaPackages.cudatoolkit
    pkgs.cudaPackages.cuda_cudart

    pkgs.sillytavern
    # pkgs.zluda

  ];
in
lib.mkIf config.custom.llm.enable {
  environment.systemPackages = with pkgs; [
    # ollama
    # ollama-cuda
    # shell-gpt
    # llm

  ] ++ additionalPackages;
  # setup port forwarding
  networking.firewall.allowedTCPPorts = [8080 9000 11434 8000 7773];
  users.users.${user}.extraGroups = ["render" "video" "ollama"];

  hardware.nvidia-container-toolkit.enable = true;

  # ollama
  # docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
  virtualisation.oci-containers.backend = "docker";

  services.ollama = {
    enable = true;
    # acceleration = "cuda";
    package = pkgs.ollama-cuda;
    group = "render";
    port = 11434;
    home = "/var/lib/private/ollama";
    openFirewall = true;
    environmentVariables = {
      OLLAMA_HOST = "0.0.0.0:11434";
      STATE_DIRECTORY = "/var/lib/private/ollama";
      OLLAMA_STATE_DIRECTORY = "/var/lib/private/ollama";
      HIP_VISIBLE_DEVICES = "0,1";
      # OLLAMA_INTEL_GPU = "1";
      OLLAMA_MAX_LOADED_MODELS = "2";
      OLLAMA_NUM_PARALLEL = "1";
      OLLAMA_DEBUG = "1";
      # q8_0 KV cache roughly halves context memory cost vs fp16 with
      # minimal quality loss, letting larger contexts fit the 3060 Ti's
      # 8GB before spilling to CPU.
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      CUDA_PATH = "${pkgs.lib.makeLibraryPath [
        pkgs.cudaPackages.cudatoolkit
        pkgs.cudaPackages.cuda_cudart
      ]}";
      LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath additionalPackages}:$LD_LIBRARY_PATH";
    };
  };

  systemd.services.ollama.environment.OLLAMA_HOST = lib.mkForce "0.0.0.0:11434";

  systemd.services.ollama = {
    serviceConfig = {
      ReadWritePaths = [ "/dev/dri" ];
      # Use ReadOnlyPaths if only read access is needed
      # ReadOnlyPaths = [ "/dev/dri" ];

      # nixpkgs' default hardening for this service otherwise breaks
      # outbound registry pulls outright (bare EOF on every attempt,
      # confirmed via side-by-side test against the same binary
      # unsandboxed). Bisected down to just these two directives -
      # everything else (ProtectSystem, ProtectHome, DynamicUser,
      # SystemCallFilter, PrivateUsers, MemoryDenyWriteExecute, etc.)
      # stays at the nixpkgs default.
      ProtectKernelTunables = lib.mkForce false;
      RestrictNamespaces = lib.mkForce false;
    };
  };

  services.sillytavern = {
    enable = true;
    port = 7773;
    listen = true;
    # Run as the real user instead of a dedicated system account - this is
    # a single-user desktop (same pattern as REAPER, Steam, etc. in this
    # config), so there's no isolation benefit to a separate sillytavern
    # user, just permission friction every time the files need touching
    # outside the app itself.
    user = user;
    group = "users";
    # Default configFile points into the Nix store (read-only). The module's
    # own tmpfiles rule symlinks /var/lib/SillyTavern/config.yaml -> this
    # path with L+, and SillyTavern writes its resolved defaults back into
    # that same file on first run - against the store, that's an EROFS and
    # the service crash-loops. Point it at a real file inside the service's
    # actual writable StateDirectory instead.
    configFile = "/var/lib/SillyTavern/data/config.yaml";
  };

  # services.open-webui = {
  #   enable = true;
  #   openFirewall = true;
  #   stateDir = "/var/lib/private/open-webui";
  #   host = "0.0.0.0";
  #   environment = {
  #     OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
  #     # Disable authentication
  #     WEBUI_AUTH = "False";
  #     ANONYMIZED_TELEMETRY = "False";
  #     DO_NOT_TRACK = "True";
  #     SCARF_NO_ANALYTICS = "True";
  #     LOCAL_FILES_ONLY = "False";
  #     USER_AGENT = "${user}";
  #   };
  # };

  # open-webui
  # pc:
  #     docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
  # server:
  #     docker run -d -p 3000:8080 -e OLLAMA_BASE_URL=https://example.com -v open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main
  # example:
  #     docker run -d --network=host -v open-webui:/app/backend/data -e OLLAMA_BASE_URL=http://127.0.0.1:11434 --name open-webui --restart always ghcr.io/open-webui/open-webui:main

  custom.persist = {
    home.directories = [
      ".ollama"
      ".cache/whisper"
    ];
    root.directories = [
      # "/var/lib/ollama"
      "/var/lib/SillyTavern/data"
      "/var/lib/SillyTavern/extensions"
      "/var/lib/private/ollama"
      "/var/lib/private/open-webui"
    ];
  };
}

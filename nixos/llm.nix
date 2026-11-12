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
    # Disabled in favor of services.llama-cpp below: Ollama's API never
    # implements the DRY sampler (SillyTavern silently drops those params
    # for it), and repeat_last_n=0 in a SillyTavern preset quietly maps to
    # Ollama's "disable repetition lookback" rather than "no limit", which
    # was letting generations copy entire paragraphs from their own prior
    # output verbatim. llama-server honors DRY and doesn't have that trap.
    # Re-enable=true any time to go back; nothing else here needs to change.
    enable = false;
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

  # Both of these unconditionally define systemd.services.ollama, which were
  # producing a unit with serviceConfig/environment overrides but no
  # ExecStart once services.ollama.enable = false dropped the module's own
  # definition ("Service has no ExecStart=... Refusing."). Gate them on the
  # same enable flag so a disabled Ollama doesn't leave a broken unit behind.
  systemd.services.ollama = lib.mkIf config.services.ollama.enable {
    environment.OLLAMA_HOST = lib.mkForce "0.0.0.0:11434";
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

  services.llama-cpp = {
    enable = true;
    package = pkgs.llama-cpp.override { cudaSupport = true; };
    settings = {
      host = "0.0.0.0";
      port = 8000;
      # Same GGUF SillyTavern was already pointing Ollama at (Q8_0, ~24GB).
      # Pulled fresh via llama-server's own HF downloader rather than reading
      # Ollama's blob store directly, so it lands in LLAMA_CACHE instead of
      # Ollama's layout - see custom.persist below for where that actually lives.
      hf-repo = "bartowski/TheDrummer_Cydonia-24B-v4.1-GGUF";
      hf-file = "TheDrummer_Cydonia-24B-v4.1-Q8_0.gguf";
      ctx-size = 20480; # matches SillyTavern's configured max_context
      # llama-server's --parallel defaults to "auto" (picked 4 on this box),
      # which reserves KV cache for 4 concurrent full-context slots even
      # though SillyTavern only ever drives one request at a time. On an
      # 8GB card that's already spilling most of a 24B model to CPU, that's
      # 3x wasted VRAM reservation for parallelism nobody uses. Pin it to 1.
      parallel = 1;
      # 24GB of Q8 weights on an 8GB 3060 Ti: "auto" (the llama-server
      # default) fits as many layers as VRAM allows and spills the rest to
      # CPU, same tradeoff Ollama was already making (see its KV cache
      # comment above) - just via a backend that doesn't eat the repetition
      # penalty doing it.
      n-gpu-layers = "auto";
      flash-attn = "on";
      cache-type-k = "q8_0";
      cache-type-v = "q8_0";
    };
  };

  # DynamicUser means no fixed uid to add to groups via users.users.*;
  # grant GPU device access directly on the unit, same devices the ollama
  # service above needs.
  systemd.services.llama-cpp.serviceConfig.SupplementaryGroups = [ "render" "video" ];

  # Upstream module wants this on multi-user.target (auto-start on every
  # boot). Loading a 24GB GGUF onto the GPU should only happen when
  # actually wanted, not on every reboot - strip that, unit stays fully
  # controllable via `systemctl start llama-cpp`.
  systemd.services.llama-cpp.wantedBy = lib.mkForce [ ];

  # Root is a 1GB tmpfs on this host (impermanence) - something recreates
  # /var/cache/private fresh on every boot/activation at the default 0755,
  # but systemd's DynamicUser CacheDirectory= machinery refuses to use it
  # unless it's 0700 ("too permissive... refusing"), killing llama-cpp with
  # CACHE_DIRECTORY at every startup until this is fixed by hand. Enforcing
  # it declaratively here instead of a one-off chmod so it survives reboots.
  #
  # Below that: every time the service failed partway through DynamicUser's
  # own public-symlink migration (the CACHE_DIRECTORY failures above being
  # exactly that trigger), it left a stray real directory at the public path
  # instead of a symlink to .../private/<name> - which then made the *next*
  # start fail too ("File exists"), requiring a manual rm -rf each time.
  # Same pattern SillyTavern's configFile already uses below: force the
  # correct symlink into place via tmpfiles (L+ removes whatever's in the
  # way first) before the service ever starts, instead of relying on
  # DynamicUser's startup-time migration logic to get it right.
  systemd.tmpfiles.rules = [
    "d /var/cache/private 0700 root root -"
    "L+ /var/cache/llama-cpp - - - - private/llama-cpp"
    "L+ /var/lib/llama-cpp - - - - private/llama-cpp"
  ];

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
      # root is a 1GB tmpfs on this host (impermanence) - without these,
      # the ~24GB GGUF llama-server pulls on first start either overflows
      # tmpfs outright or gets wiped and re-downloaded on every reboot.
      # DynamicUser services keep their real Cache/StateDirectory under
      # .../private/<name>, with .../<name> as a symlink systemd manages
      # itself - persisting the public path (like /var/lib/ollama, which
      # the ollama entry below correctly avoids) collides with that symlink
      # and fails the service with "Device or resource busy".
      "/var/cache/private/llama-cpp"
      "/var/lib/private/llama-cpp"
    ];
  };
}

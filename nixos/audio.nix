{
  pkgs,
  user,
  lib,
  config,
  ...
}: {
  config = {
    # setup pipewire for audio
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
    services.pulseaudio.enable = false;

    systemd.user.services.pipewire.serviceConfig.AllowedCPUs = "3 4 5";
    systemd.user.services.wireplumber.serviceConfig.AllowedCPUs = "3 4 5";
    systemd.user.services.pipewire-pulse.serviceConfig.AllowedCPUs = "3 4 5";

    # services.jack = {
    #   jackd.enable = true;
    #   # support ALSA only programs via ALSA JACK PCM plugin
    #   alsa.enable = false;
    #   # support ALSA only programs via loopback device (supports programs like Steam)
    #   loopback = {
    #     enable = true;
    #     # buffering parameters for dmix device to work with ALSA only semi-professional sound programs
    #     dmixConfig = ''
    #       period_size 1024
    #     '';
    #   };
    # };

    # systemd.services.jack = {

    #   serviceConfig = {
    #     # ExecStart = lib.mkForce "${pkgs.jack2}/bin/jackd -R -P85 -dalsa -dhw:10 -r48000 -p512 -n2";

    #     AllowedCPUs = lib.mkForce "4 5";
    #     LimitRTPRIO = lib.mkForce 95;
    #     LimitMEMLOCK = lib.mkForce "infinity";
    #   };
    # };


    security.pam.loginLimits = [
      { domain = "${user}"; type = "-"; item = "rtprio"; value = "95"; }
      { domain = "${user}"; type = "-"; item = "memlock"; value = "unlimited"; }
      { domain = "${user}"; type = "-"; item = "nice"; value = "-20"; }
    ];

    services.pipewire.extraConfig.pipewire."91-rt-affinity" = {
      context.properties = {
        "cpu.affinity" = "3,4,5";
      };
    };

    services.pipewire.extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];
        "default.clock.quantum" = 512;
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 512;
      };
    };

    musnix = {
      enable = true;
      rtcqs.enable = true;
      kernel.realtime = true;
      das_watchdog.enable = true;
      rtirq = {
        enable = true;
        nameList = "xhci snd";
      };
    };
    users.users.${user} = {
      extraGroups = ["jackaudio" "audio" ];
    };

    custom.persist.home.directories = [
      ".config/rncbc.org"
      ".local/share/easyeffects"
      ".config/easyeffects"
    ];    

    environment.systemPackages = with pkgs; [
      sox
      alsa-lib
      alsa-utils
      pavucontrol
      crosspipe
      easyeffects
      pulseaudio
      qjackctl
      qpwgraph
      # jack2
      vmpk # piano
    ];
  };
}

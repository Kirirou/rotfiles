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
    systemd.user.services.pipewire.serviceConfig.AllowedCPUs = "5";
    systemd.user.services.wireplumber.serviceConfig.AllowedCPUs = "5";
    systemd.user.services.pipewire-pulse.serviceConfig.AllowedCPUs = "5";
    security.pam.loginLimits = [
      { domain = "${user}"; type = "-"; item = "rtprio"; value = "95"; }
      { domain = "${user}"; type = "-"; item = "memlock"; value = "unlimited"; }
      { domain = "${user}"; type = "-"; item = "nice"; value = "-20"; }
    ];
    services.pipewire.extraConfig.pipewire."91-rt-affinity" = {
      context.properties = {
        "cpu.affinity" = "5";
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
    hm.systemd.user.sessionVariables = {
      LD_LIBRARY_PATH = "${pkgs.pipewire.jack}/lib";
    };
    hm.wayland.windowManager.hyprland.settings.env = [
      { _args = ["LD_LIBRARY_PATH" "${pkgs.pipewire.jack}/lib"]; }
    ];

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
      vmpk
      rnnoise
      rnnoise-plugin
      pipewire.jack
    ];
    # easyeffects rnnoise preset
    hm.home.file.".config/easyeffects/input/rnnoise.json".text = builtins.toJSON {
      input = {
        blocklist = [];
        plugins_order = ["rnnoise"];
        rnnoise = {
          bypass = false;
          enable-va = true;
          input-gain = 0.0;
          model-name = "";
          model-path = "";
          output-gain = 0.0;
          release-time = 20.0;
          vad-thres = 50.0;
        };
      };
    };
  };
}

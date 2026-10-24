{
  pkgs,
  user,
  lib,
  config,
  ...
}: {
  config = {
    # Pipewire/wireplumber below are pinned to CPU 5 via AllowedCPUs, but
    # that's only a soft affinity hint - the general scheduler can still
    # put other work on CPU 5, contending with the realtime audio thread.
    # isolcpus pulls CPUs 4-5 out of the default SMP scheduling domain (only
    # processes explicitly affined to them, like pipewire and REAPER below,
    # will run there); nohz_full/rcu_nocbs stop timer ticks and RCU
    # callbacks from interrupting them too. This makes the audio isolation
    # an actual guarantee instead of a hint the scheduler can ignore.
    #
    # Core 4 is included alongside 5 because REAPER (see
    # home-manager/programs/reaper.nix's "5reaper") only gets a soft
    # `taskset -c 4-5`, not a single-core pin - its own audio engine thread
    # can land on either core. Isolating only 5 protected pipewire but left
    # REAPER's thread exposed to contention whenever the scheduler happened
    # to place it on 4, which is still open to everything else on the
    # system (confirmed: xruns during a full streaming+tracking pipeline
    # even with 5reaper in use).
    boot.kernelParams = [ "isolcpus=4,5" "nohz_full=4,5" "rcu_nocbs=4,5" ];

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

    # Highest io.weight slice for the whole realtime audio path - not just
    # the pipewire daemon, but anything doing audio-critical work (REAPER
    # itself included - a stalled sample load in REAPER is just as audible
    # as pipewire stalling). io.weight only does anything once BFQ is the
    # active scheduler on the relevant drives (see boot.kernelPatches in
    # hosts/desktop/hardware.nix and the scheduler-selection service
    # below) - without BFQ, this is inert and the kernel just ignores it.
    systemd.slices.realtime-audio = {
      description = "Realtime audio path - highest IO priority";
      sliceConfig = {
        IOWeight = 10000; # max
      };
    };

    systemd.user.services.pipewire.serviceConfig = {
      AllowedCPUs = "5";
      Slice = "realtime-audio.slice";
      # Best-effort IOSchedulingClass at the highest priority (0) - realtime
      # class needs CAP_SYS_ADMIN, which a user service doesn't have by
      # default. This still jumps the block I/O queue ahead of normal
      # processes (eg. a bulk rsync/zfs send) if pipewire ever does touch
      # disk, without granting extra privileges to get there.
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 0;
    };
    systemd.user.services.wireplumber.serviceConfig = {
      AllowedCPUs = "5";
      Slice = "realtime-audio.slice";
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 0;
    };
    systemd.user.services.pipewire-pulse.serviceConfig = {
      AllowedCPUs = "5";
      Slice = "realtime-audio.slice";
      IOSchedulingClass = "best-effort";
      IOSchedulingPriority = 0;
    };

    # BFQ is cgroup-weight-aware (none/mq-deadline/kyber aren't) - without
    # this, systemd.slices.realtime-audio's IOWeight above does nothing.
    # Applies to every real block device (not just zroot) since REAPER
    # streams sample libraries off wdc-blue too.
    systemd.services.bfq-scheduler-all-disks = {
      description = "Use the BFQ IO scheduler everywhere, for cgroup io.weight support";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "bfq-scheduler-all-disks" ''
          for q in /sys/block/sd*/queue /sys/block/nvme*n*/queue; do
            [ -f "$q/scheduler" ] && echo bfq > "$q/scheduler" 2>/dev/null || true
          done
        ''}";
      };
    };

    # CPU isolation (isolcpus) only stops other *processes* landing on cores
    # 4-5 - hardware interrupts are routed independently and still default
    # to every core (mask 3f = cores 0-5). Without this, disk/USB
    # controller IRQs (nvme, ahci, xhci) can still land on and interrupt
    # the isolated audio cores - xhci in particular matters if the audio
    # interface is USB. Pin them to cores 0-3 (mask 0f) instead, at boot.
    systemd.services.irq-affinity-exclude-audio-core = {
      description = "Keep disk/USB controller IRQs off the isolated audio cores (4-5)";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "irq-affinity-exclude-audio-core" ''
          while IFS= read -r line; do
            irq="${"\${line%%:*}"}"
            irq="${"\${irq// /}"}"
            echo 0f > "/proc/irq/$irq/smp_affinity" 2>/dev/null || true
          done < <(grep -E "nvme|ahci|xhci_hcd" /proc/interrupts)
        ''}";
      };
    };

    # isolcpus keeps the scheduler off cores 4-5, but the idle driver still
    # parks them in deep C-states between wakeups (pipewire's ~10.6ms
    # quantum=512 @ 48kHz, and REAPER's own audio callback on whichever of
    # 4/5 it lands on) - exit latency from those states is the kind of
    # unpredictable spike that causes an xrun specifically under load, when
    # something else on the system is also waking up cores around the same
    # time. Disable every C-state past C1 on both isolated cores, so
    # neither sleeps deep enough to matter. Costs a few idle watts on two
    # cores - cheap next to the RT kernel/isolcpus cost already paid.
    systemd.services.disable-deep-cstates-audio-core = {
      description = "Keep the isolated audio cores (4-5) out of deep C-states";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysinit.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.writeShellScript "disable-deep-cstates-audio-core" ''
          for state in /sys/devices/system/cpu/cpu{4,5}/cpuidle/state*/disable; do
            [ "$(basename "$(dirname "$state")")" = "state0" ] && continue
            [ "$(basename "$(dirname "$state")")" = "state1" ] && continue
            echo 1 > "$state" 2>/dev/null || true
          done
        ''}";
      };
    };
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

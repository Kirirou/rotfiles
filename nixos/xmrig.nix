{
  config,
  pkgs,
  lib,
  user,
  ...
}:
let
  cfg = config.custom.xmrig;
  json = pkgs.formats.json { };

  mkConfig =
    { cpuEnabled, cudaEnabled }:
    json.generate "xmrig-config.json" {
      autosave = true;
      cpu = {
        enabled = cpuEnabled;
        # "max-threads-hint": 100 only ever yielded 5/6 threads in practice
        # (RandomX's own heuristic reserves headroom by default). `rx` is
        # an explicit per-algorithm thread count - set directly, it forces
        # the real max, same as the `--threads=6` CLI flag confirmed
        # earlier.
        rx = 6;
      };
      randomx = {
        # Needs the 1G-page kernel reservation below (boot.kernelParams);
        # falls back to the regular 2MB hugepages if that pool isn't
        # available for some reason, not a hard failure.
        "1gb-pages" = true;
      };
      opencl = false;
      cuda = {
        enabled = cudaEnabled;
        loader = "${pkgs.xmrig-cuda}/lib/libxmrig-cuda.so";
        # No pinned devices/intensity - auto-max against whatever's free.
      };
      pools = [
        {
          url = "gulf.moneroocean.stream:20004";
          user = "49WjRAbRYvcSyREQ9ZRDsUgLA3SDRD8hBHnd7KU3d3SbRnmmvZTBtbg22W7khw1m2r5NWC9Bbf4nAQFnHbL4mP8ALEppwNf";
          "rig-id" = "desktop";
          keepalive = true;
          tls = true;
        }
      ];
    };

  mkService =
    { cpuEnabled, cudaEnabled }:
    {
      description = "XMRig mining (manual start only)";
      # Deliberately no wantedBy - only ever starts via an explicit
      # `systemctl start` (through `xm`, or directly), never automatically.
      serviceConfig = {
        Type = "simple";
        # Runs as the regular user, not root - CAP_SYS_RAWIO is granted
        # directly by systemd (AmbientCapabilities) rather than via a
        # file-capability wrapper. That distinction matters: a file-cap
        # wrapper puts the process in glibc's secure-exec mode for its
        # whole lifetime (silently dropping LD_LIBRARY_PATH, which broke
        # NVML's dlopen lookup no matter what got RPATH-patched); ambient
        # capabilities are a subset of what the process already holds
        # rather than privilege gained via the exec'd file, so the kernel
        # doesn't flag this as a secureexec - LD_LIBRARY_PATH below works
        # normally.
        User = user;
        AmbientCapabilities = [ "CAP_SYS_RAWIO" ];
        CapabilityBoundingSet = [ "CAP_SYS_RAWIO" ];
        Environment = "LD_LIBRARY_PATH=/run/opengl-driver/lib";
        ExecStart = "${pkgs.xmrig}/bin/xmrig --config=${mkConfig { inherit cpuEnabled cudaEnabled; }}";
        Restart = "no";
      };
    };
in
{
  config = lib.mkIf cfg.enable {
    # RandomX's MSR mod needs CAP_SYS_RAWIO (checked explicitly by the
    # kernel's msr driver regardless of file permissions) plus DAC access to
    # /dev/cpu/*/msr. `mode = "0660"` + group membership covers the DAC
    # side; AmbientCapabilities on the services below covers the
    # capability side.
    hardware.cpu.x86.msr = {
      enable = true;
      mode = "0660";
      settings.allow-writes = "on";
    };

    users.users.${user}.extraGroups = [ "msr" ];

    # The RandomX dataset (2336MB / 1168 * 2MB pages) was getting backed by
    # transparent huge pages fine on its own, but each CPU thread's own
    # 2MB scratchpad buffer was still landing on regular 4K pages (`huge
    # pages 0% 0/5` in xmrig's own log) since this system had zero static
    # hugepages reserved. 1280 pages (~2.5GB) covers the dataset plus
    # scratchpads for all 6 threads with headroom, trivial against 62GB RAM.
    boot.kernel.sysctl."vm.nr_hugepages" = 1280;

    # Separate 1GB-page pool for the RandomX dataset itself: 3 pages covers
    # the ~2.3GB dataset with just 3 page-table entries instead of 1168 at
    # 2MB each, cutting TLB misses on the random lookups RandomX is built
    # around. Unlike the 2MB pool above, 1GB pages can only be reserved on
    # the kernel command line (contiguous memory has to be carved out
    # before anything fragments it) - boot param only, needs a reboot, and
    # permanently takes 3GB out of general use while reserved. CPU support
    # confirmed via `pdpe1gb` in /proc/cpuinfo.
    boot.kernelParams = [
      "hugepagesz=1G"
      "hugepages=3"
    ];

    systemd.services = {
      xmrig = mkService {
        cpuEnabled = true;
        cudaEnabled = true;
      };
      xmrig-cpu = mkService {
        cpuEnabled = true;
        cudaEnabled = false;
      };
      xmrig-gpu = mkService {
        cpuEnabled = false;
        cudaEnabled = true;
      };
    };

    # Plain `systemctl start/stop` on a system unit normally triggers a
    # polkit password prompt for a non-root user. Scope passwordless auth
    # to just these three units/actions instead of a blanket sudo grant,
    # so `xm`/`systemctl start xmrig` stays a single no-password command.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        var xmrigUnits = ["xmrig.service", "xmrig-cpu.service", "xmrig-gpu.service"];
        if ((action.id == "org.freedesktop.systemd1.manage-units") &&
            xmrigUnits.indexOf(action.lookup("unit")) != -1 &&
            subject.user == "${user}") {
          return polkit.Result.YES;
        }
      });
    '';
  };
}

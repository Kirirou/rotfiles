{ ... }:
{
  # systemd-oomd runs by default but NixOS ships it toothless: no slice opts
  # in, so ManagedOOMMemoryPressure/ManagedOOMSwap stay "auto" everywhere and
  # it never actually kills anything. A single leaking process can walk RAM +
  # swap to ~100% full for hours before the kernel's own last-resort OOM
  # killer steps in - by which point the system has been under enough
  # sustained memory pressure to risk destabilizing other subsystems (ZFS
  # compression codecs faulting on corrupted buffers has been observed here).
  # Wire it up to actually intervene early, on both pressure and swap %.
  systemd.oomd = {
    enableRootSlice = true;
    enableUserSlices = true;
    settings.OOM.SwapUsedLimit = "75%";
  };

  systemd.slices."-".sliceConfig.ManagedOOMSwap = "kill";
  systemd.slices."user".sliceConfig.ManagedOOMSwap = "kill";
}

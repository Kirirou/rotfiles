{
  config,
  lib,
  pkgs,
  user,
  ...
}:
{
  config = lib.mkIf config.custom.nvidia.enable {
    # enable nvidia support
    services.xserver.videoDrivers = [ "nvidia" "modesetting" ];

    boot = {
      # nvidia-uvm is required for CUDA applications.
      # nvidia/nvidia_modeset/nvidia_drm are normally auto-added by the nixpkgs
      # nvidia module, but only when services.xserver.enable is true. This is a
      # Wayland-only (Hyprland) setup with xserver disabled, so they'd otherwise
      # only load via PCI-based udev autoprobe, which is racy against session
      # start and silently leaves Hyprland on a fake fallback monitor if it loses
      # the race. List them explicitly so they're always loaded at boot.
      kernelModules = [ "nvidia-uvm" "nvidia" "nvidia_modeset" "nvidia_drm" ];
      # use nvidia framebuffer
      # https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers#Kernel_module_parameters for more info.
      kernelParams = [ 
        "nvidia-drm.fbdev=1" "nvidia-drm.modeset=1"
        "i915.force_probe=3e92"
        "i915.modeset=1"
        "i915.enable_gvt=1"
        "i915.enable_dpcd_backlight=1"
        "psi=1"
       ];
    };

    hardware = {
      nvidia = {
        modesetting.enable = true;
        powerManagement.enable = true;
        # Both beta (595.45.04) and production (595.84) open kernel modules
        # crash identically under heavy Blender/CUDA GPU memory churn: repeated
        # "Failed to insert new mapping node" / gpu_vaspace.c assertion failures
        # followed by a GPF in nvidia_uvm's lazy-free worker. Signature points to
        # a bug in the open modules' VA-space bookkeeping during memory
        # oversubscription, not a specific version. Falling back to the closed
        # kernel modules, and to the newest available branch while we're at it.
        open = false;
        nvidiaSettings = false;
        package = config.boot.kernelPackages.nvidiaPackages.latest;
        # Without persistence mode, the driver lets the GPU drop its
        # initialized clock/power state between GPU contexts, forcing a
        # re-ramp stall on the next client. On a desktop that constantly
        # opens/closes GPU clients (browser, OBS, Proton games, REAPER
        # plugin UIs, CUDA jobs), this is a classic source of periodic
        # stutter that gets worse the longer a session runs.
        nvidiaPersistenced = true;
      };
      graphics.extraPackages = with pkgs; [
        intel-vaapi-driver
        libva-vdpau-driver
        vaapi-intel-hybrid
        libvdpau-va-gl
        intel-vaapi-driver
        intel-media-driver
        intel-gmmlib
        libva
        libva-utils
        libva-vdpau-driver
        # intel-compute-runtime
        vpl-gpu-rt
        ocl-icd
        intel-ocl
        nvidia-vaapi-driver

        vulkan-loader
        vulkan-headers
        vulkan-extension-layer
        vulkan-memory-allocator
        vulkan-validation-layers
        vulkan-utility-libraries
        libxi libxmu freeglut
        libxext libx11 libxv libxrandr zlib 
        linuxPackages.nvidia_x11
        libGLU libGL
        linuxHeaders
        libdrm
        libgbinder
        icu
        glfw
        mesa
        # swiftshader
        egl-wayland
      ];
    };
    environment.systemPackages = with pkgs; [
        icu
        glfw
        
        mesa

        # nvtopPackages.full
        mesa-demos
        clinfo
        inxi
        drm_info
        vulkan-tools

        vulkan-loader
        vulkan-headers
        vulkan-extension-layer
        vulkan-memory-allocator
        vulkan-validation-layers
        vulkan-utility-libraries

        # cudaPackages.cudatoolkit
        # cudaPackages.cudnn
        # cudaPackages.cuda_cudart

        linuxHeaders
        libdrm
        libgbinder
    ];

    environment.sessionVariables =
      {
        NIXOS_OZONE_WL = "1";
        MOZ_ENABLE_WAYLAND = "1";
        NVD_BACKEND = "direct";
        LIBVA_DRM_DEVICE = "/dev/dri/renderD128";
        MOZ_DISABLE_RDD_SANDBOX = "1";
      }
      // lib.optionalAttrs config.programs.hyprland.enable {
        LIBVA_DRIVER_NAME = "nvidia";
        GBM_BACKEND = "nvidia-drm";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      };
    
    custom.persist = {
      root.cache = [
        "/home/${user}/.cache/nvidia"
      ];
    };

    nix.settings = {
      # substituters = [ "https://cuda-maintainers.cachix.org" ];
      trusted-public-keys = [
        # "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
      ];
    };
  };
}

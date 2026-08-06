{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.obs-studio;
in {
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.droidcam
    ];
    programs.obs-studio = {
      enable = true;
      package = pkgs.obs-studio.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/obs \
            --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
        '';
      });

      plugins = with pkgs.obs-studio-plugins; [
        wlrobs                    # Screencast capture for Wayland compositors [https://github.com/CatxFish/wlrobs]
        obs-vnc                   # VNC viewer source to display a remote desktop [https://github.com/norihiro/obs-vnc]
        # distroav                  # NDI (Network Device Interface) integration for OBS Studio [https://github.com/DistroAV/DistroAV]
        waveform                  # Audio spectral analysis plugin (visualizes audio spectrum) [https://github.com/phandasm/waveform]
        obs-vaapi                 # VAAPI hardware encoding via GStreamer (Linux GPU encoder) [https://github.com/fzwoch/obs-vaapi]
        obs-noise                 # Animated fractal noise source and displacement filter [https://github.com/FiniteSingularity/obs-noise]
        pixel-art                 # Retro-inspired pixel art visual effect [https://github.com/dspstanky/pixel-art]
        droidcam-obs              # Use a phone as a high-quality camera source via DroidCam [https://github.com/dev47apps/droidcam-obs-plugin]
        obs-teleport              # Open NDI-like plugin for streaming between OBS instances [https://github.com/fzwoch/obs-teleport]
        obs-markdown              # Add formatted Markdown text as a source [https://github.com/exeldro/obs-markdown]
        obs-gstreamer             # Use custom GStreamer pipelines as sources in OBS [https://github.com/fzwoch/obs-gstreamer]
        input-overlay             # Show keyboard, mouse, and gamepad inputs on stream [https://github.com/univrsal/input-overlay]
        obs-vkcapture             # Vulkan/OpenGL game capture plugin for Linux [https://github.com/nowrep/obs-vkcapture]
        obs-3d-effect             # 3D transform effect filter for sources (rotate in 3D space) [https://github.com/exeldro/obs-3d-effect]
        obs-websocket             # WebSocket API for OBS Studio (remote control interface) [https://github.com/obsproject/obs-websocket]
        obs-multi-rtmp            # Stream to multiple RTMP servers simultaneously (multi-stream) [https://github.com/sorayuki/obs-multi-rtmp]
        obs-rgb-levels            # Simple filter to adjust input RGB color levels [https://github.com/petrifiedpenguin/obs-rgb-levels-filter]
        obs-mute-filter           # Filter to mute a source’s audio output [https://github.com/norihiro/obs-mute-filter]
        obs-shaderfilter          # Apply custom shader effects to sources (via user-defined shaders) [https://github.com/exeldro/obs-shaderfilter]
        obs-text-pthread          # Rich text source plugin (supports Pango markup and transitions) [https://github.com/norihiro/obs-text-pthread]
        obs-source-clone          # Clone a source to apply different filters than the original [https://github.com/exeldro/obs-source-clone]
        obs-freeze-filter         # Freeze a source at its current frame (pause video playback) [https://github.com/exeldro/obs-freeze-filter]
        # obs-color-monitor         # Vectorscope, waveform, and histogram scopes for color monitoring [https://github.com/norihiro/obs-color-monitor]
        looking-glass-obs         # Capture a Looking Glass (VM framebuffer) feed directly as a source [https://looking-glass.io/docs/B5.0.1/obs/]
        obs-source-record         # Record a source or scene to a separate video file (source recording) [https://github.com/exeldro/obs-source-record]
        obs-retro-effects         # Filters simulating retro hardware (CRTs, analog TV, VHS effects) [https://github.com/FiniteSingularity/obs-retro-effects]
        obs-replay-source         # Instant replay source (play back recent footage with slow-motion) [https://github.com/exeldro/obs-replay-source]
        obs-livesplit-one         # Add LiveSplit One (speedrunning timer) as an OBS source [https://github.com/LiveSplit/obs-livesplit-one]
        obs-media-controls        # Add a dock with playback controls for media sources (play/pause/seek) [https://github.com/exeldro/obs-media-controls]
        obs-advanced-masks        # Advanced masking filters (alpha and color masks) for sources and scenes [https://github.com/FiniteSingularity/obs-advanced-masks]
        obs-vintage-filter        # Black-and-white or sepia (vintage look) filter for sources [https://github.com/cg2121/obs-vintage-filter]
        obs-scale-to-sound        # Scale a source based on audio input levels (reactive to sound) [https://github.com/dimtpap/obs-scale-to-sound]
        obs-command-source        # Dummy source to run arbitrary commands on scene switch [https://github.com/norihiro/obs-command-source]
        obs-composite-blur        # Multiple optimized blur filters (Gaussian, box, dual Kawase, etc.) [https://github.com/FiniteSingularity/obs-composite-blur]
        obs-dvd-screensaver       # DVD screensaver bouncing logo source (retro idle animation) [https://github.com/wimpysworld/obs-dvd-screensaver]
        obs-dir-watch-media       # Auto-load the newest (or oldest) file from a directory into a media source [https://github.com/exeldro/obs-dir-watch-media]
        # obs-vertical-canvas       # Add a vertical (9:16) canvas for portrait/ mobile streaming (Aitum Vertical) [https://github.com/Aitum/obs-vertical-canvas]
        obs-source-switcher       # Source that automatically switches between a list of sources [https://github.com/exeldro/obs-source-switcher]
        obs-gradient-source       # Gradient color source (two-color or multi-color gradient background) [https://github.com/exeldro/obs-gradient-source]
        obs-move-transition       # Animate sources between scenes (move source transition effect) [https://github.com/exeldro/obs-move-transition]
        obs-recursion-effect      # Recursive “infinite mirror” video effect filter for a source [https://github.com/exeldro/obs-recursion-effect]
        obs-transition-table      # Define custom scene transitions for specific scene pairs [https://github.com/exeldro/obs-transition-table]
        obs-aitum-multistream     # Multistream plugin to broadcast to multiple platforms at once [https://github.com/Aitum/obs-aitum-multistream]
        obs-backgroundremoval     # AI-powered background removal (virtual green screen) for cameras [https://github.com/royshil/obs-backgroundremoval]
        obs-stroke-glow-shadow    # Stroke (outline), glow, and shadow effect filters for sources [https://github.com/FiniteSingularity/obs-stroke-glow-shadow]
        advanced-scene-switcher   # Highly configurable automatic scene switching with custom rules (macros) [https://github.com/WarmUpTill/SceneSwitcher]
      ];
    };

    custom.persist = {
      home.directories = [
        ".config/obs-studio"
      ];
    };
  };
}

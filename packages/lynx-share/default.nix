{
  lib,
  stdenv,
  buildFHSEnv,
  copyDesktopItems,
  makeDesktopItem,
  alsa-lib,
  fontconfig,
  freetype,
  libGL,
  dbus,
  libjack2,
  pipewire,
  libx11,
  libxcursor,
  libxext,
  libxinerama,
  libxrandr,
  libXScrnSaver,
  # <- this comes from nvfetcher via your helper `w`
  source,
}:

let
  pname = source.pname or "lynx-share";
  version = source.version;

  # LYNX dlopen()s X11/audio libs at runtime instead of linking them
  # directly (confirmed via `strings LYNX | grep '\.so'`), so a plain
  # autoPatchelfHook pass over the single NEEDED libs it does declare
  # (alsa/fontconfig/freetype/GL/libc) isn't enough - it'd still fail to
  # find libX11/libjack/libpipewire/etc at runtime. buildFHSEnv sidesteps
  # that entirely by giving it a real /usr/lib to dlopen from.
  lynx-share = stdenv.mkDerivation {
    inherit pname version;
    src = source.src;

    nativeBuildInputs = [ copyDesktopItems ];

    desktopItems = [
      (makeDesktopItem {
        name = "lynx-share";
        exec = "lynx-share %F";
        desktopName = "LYNX SHARE";
        genericName = "Digital Audio Workstation";
        comment = "A lightweight DAW, fully open source";
        icon = "lynx-share";
        categories = [ "AudioVideo" "Audio" "Midi" "Music" "Sequencer" ];
        mimeTypes = [ "application/x-lynx-project" ];
      })
    ];

    installPhase = ''
      runHook preInstall

      install -Dm755 LYNX "$out/bin/lynx-share"
      install -Dm444 lynx.png "$out/share/pixmaps/lynx-share.png"
      install -Dm444 lynx-mime.xml "$out/share/mime/packages/lynx-share-mime.xml"

      runHook postInstall
    '';
  };

in
buildFHSEnv {
  inherit (lynx-share) pname version;

  targetPkgs = pkgs: [
    alsa-lib
    lynx-share
    fontconfig
    freetype
    libGL
    dbus
    libjack2
    pipewire
    libx11
    libxcursor
    libxext
    libxinerama
    libxrandr
    libXScrnSaver
  ];

  runScript = "lynx-share";

  extraInstallCommands = ''
    cp -r ${lynx-share}/share $out/share
  '';

  meta = with lib; {
    description = "Lightweight, fully open-source DAW with an FL Studio-style workflow (Linux binary release via nvfetcher)";
    homepage = "https://github.com/Ka1-S/LYNX-SHARE";
    license = licenses.agpl3Only;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    mainProgram = "lynx-share";
    platforms = [ "x86_64-linux" ];
  };
}

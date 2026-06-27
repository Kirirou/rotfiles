{
  lib,
  buildNpmPackage,
  electron_42,
  makeWrapper,
  source,
}:
buildNpmPackage {
  pname = "sysmocap";
  version = source.version;
  src = source.src;

  npmDepsHash = "sha256-u0jF9rt5UQtJ0h9disa3QGAQJHGU/FvNcHhv0gA+8JU=";

  ELECTRON_SKIP_BINARY_DOWNLOAD = "1";

  nativeBuildInputs = [ makeWrapper ];

  npmBuildScript = "build";

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/sysmocap $out/bin

    cp -r dist main.js package.json node_modules \
          fonts models icons pdfs pdfviewer webserv utils \
          $out/lib/sysmocap/

    makeWrapper ${electron_42}/bin/electron $out/bin/sysmocap \
      --add-flags $out/lib/sysmocap

    runHook postInstall
  '';

  meta = with lib; {
    description = "Real-time motion capture system using MediaPipe and VRM";
    homepage = "https://github.com/xianfei/SysMocap";
    license = licenses.gpl3Only;
    mainProgram = "sysmocap";
    platforms = [ "x86_64-linux" ];
  };
}

{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  glibc,
  cacert,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dropstone";
  version = "1.0.67";

  # Upstream has no GitHub releases - just a custom download server with a
  # latest.txt and versioned tarballs (see https://dropstone.io/install).
  # Pinned manually rather than via nvfetcher since there's no feed nvfetcher
  # understands for this host.
  src = fetchurl {
    url = "https://download.dropstone.io/v${finalAttrs.version}/dropstone-linux-x64.tar.gz";
    hash = "sha256-zUD+PNhK6D3J6RASRpPWU/LmhVK7ld1JiNrF0uFNliU=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];

  # The archive has dropstone/LICENSE directly at the top level (no wrapping
  # directory), so stdenv's default "cd into the one extracted dir" unpack
  # logic has nothing to cd into.
  sourceRoot = ".";

  # The upstream binary advertises itself as "statically-linked" but is
  # actually a dynamically linked glibc binary (interpreter
  # /lib64/ld-linux-x86-64.so.2, NEEDED: libc/libpthread/libdl/libm) -
  # confirmed via readelf. autoPatchelfHook just needs glibc to fix that up.
  buildInputs = [ glibc ];

  installPhase = ''
    runHook preInstall
    install -Dm755 dropstone "$out/bin/dropstone"
    install -Dm444 LICENSE "$out/share/licenses/dropstone/LICENSE"
    runHook postInstall
  '';

  # Go's net/http looks for /etc/ssl/certs/ca-certificates.crt, which may
  # not exist depending on system config - point it at nixpkgs' cacert bundle
  # explicitly so sign-in/API calls don't fail TLS verification.
  postFixup = ''
    wrapProgram "$out/bin/dropstone" \
      --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  meta = {
    description = "AI coding agent CLI with memory";
    homepage = "https://dropstone.io";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "dropstone";
    platforms = [ "x86_64-linux" ];
  };
})

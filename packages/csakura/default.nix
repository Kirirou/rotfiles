{
  lib,
  stdenv,
  pkg-config,
  ncurses,
  source,
}:

stdenv.mkDerivation {
  pname = source.pname or "csakura";
  version = source.version;
  src = source.src;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ ncurses ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = with lib; {
    description = "Terminal cherry blossom tree animation";
    homepage = "https://github.com/realstrawhat/csakura";
    license = licenses.mit;
    mainProgram = "csakura";
    platforms = platforms.linux;
  };
}

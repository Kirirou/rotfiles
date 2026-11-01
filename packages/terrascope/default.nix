{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication rec {
  pname = "terrascope";
  version = "1.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "a-shygun";
    repo = "Terrascope";
    rev = "v${version}";
    hash = "sha256-emrWNgaGbsAbm3ZMTMnbgcNlFzUU/a+4O7jMIRRx/8k=";
  };

  build-system = [ python3Packages.hatchling ];

  dependencies = with python3Packages; [
    numpy
    pillow
    pyyaml
    pyshp
  ];

  meta = with lib; {
    description = "Braille-rendered terminal world map with live weather, aircraft, earthquakes, and day/night layers";
    homepage = "https://github.com/a-shygun/Terrascope";
    license = licenses.mit;
    mainProgram = "terrascope";
    platforms = platforms.unix;
  };
}

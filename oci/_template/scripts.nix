{
  pkgs,
  crossPkgs,
  ...
}: let
  src = ./scripts;
in
  pkgs.stdenv.mkDerivation {
    name = "scripts";
    version = "1.0.0";

    phases = ["installPhase"];

    installPhase = ''
      mkdir --parents $out/bin

      for FILE in $(find ${src} -type f);
      do
        install --verbose $FILE $out/bin/$(basename ''${FILE%.*})
        chmod +x $out/bin/$(basename ''${FILE%.*})
      done
    '';

    meta = {
      description = "Wrapper scripts for working with the bundled CLI tools.";
      homepage = "https://saltlabs.tech";
      license = "Unlicense";
    };
  }

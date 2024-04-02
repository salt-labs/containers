{
  pkgs,
  system,
  poetry2nix,
}: let
  inherit (poetry2nix.legacyPackages.${system}) mkPoetryApplication;

  pythonPkg = pkgs.python3;
in
  mkPoetryApplication {
    projectDir = ./.;

    preferWheel = true;

    python = pythonPkg;

    postPatch = ''
      # Figure out the location of poetry.core
      # As poetry.core is using the same root import name as the poetry package and the python module system wont look for the root
      # in the separate second location we need to link poetry.core to poetry
      POETRY_CORE=$(python -c 'import poetry.core; import os.path; print(os.path.dirname(poetry.core.__file__))')
      mkdir -p src/poetry
      echo "import sys" >> src/poetry/__init__.py
      for path in $propagatedBuildInputs;
      do
        echo "sys.path.insert(0, \"$path\")" >> src/poetry/__init__.py
      done
    '';

    postInstall = ''
      ln -s $POETRY_CORE $out/${pythonPkg.sitePackages}/poetry/core
      mkdir -p "$out/share/bash-completion/completions"
      "$out/bin/poetry" completions bash > "$out/share/bash-completion/completions/poetry"
    '';

    postFixup = ''
      rm $out/nix-support/propagated-build-inputs
    '';

    doCheck = false;

    meta = {
      description = "Python Poetry application.";
      homepage = "https://python-poetry.org/";
      license = "MIT";
    };
  }

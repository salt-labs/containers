{pkgs, ...}: let
  packageOverrides = pkgs.callPackage ./python-packages.nix {};
  python = pkgs.python3.override {inherit packageOverrides;};
  pythonWithPackages = python.withPackages (ps: [ps.requests]);
in
  pkgs.stdenv.mkDerivation {
    name = "idem";
    version = "1.0.0";

    src = ./.;

    phases = ["installPhase"];

    buildInputs = [
      pythonWithPackages
    ];

    meta = {
      description = "Liberation From The Cloud.";
      homepage = "https://www.idemproject.io/";
      license = "Apache 2.0";
    };
  }

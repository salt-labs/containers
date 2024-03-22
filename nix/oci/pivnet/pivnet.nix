{pkgs, ...}: let
  pivnet = pkgs.fetchurl {
    name = "pivnet";
    url = "https://github.com/pivotal-cf/pivnet-cli/releases/download/v3.0.1/pivnet-linux-amd64-3.0.1";
    sha256 = "sha256-et44d6fpcyJ8WMrGrjpRrXiBMDh8FmRjaR/gjzd5KPw=";
  };
in
  pkgs.stdenv.mkDerivation {
    name = "pivnet";
    version = "v3.0.1";

    phases = ["installPhase"];

    installPhase = ''
      mkdir --parents $out/bin

      install --verbose ${pivnet} $out/bin/pivnet
    '';

    meta = {
      description = "CLI to interact with Tanzu Network API V2 interface.";
      homepage = "https://github.com/pivotal-cf/pivnet-cli";
      license = "Apache 2.0";
    };
  }

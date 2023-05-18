{
  pkgs,
  crossPkgs,
  ...
}: let
  kpack = {
    cli = pkgs.fetchurl {
      name = "kpack-cli";
      url = "https://github.com/vmware-tanzu/kpack-cli/releases/download/v0.9.1/kp-linux-amd64-0.9.1";
      sha256 = "sha256-F10IGO2D59hPFp3XTCZTHTKMwJcZN/IVijrf77z1f9s=";
    };

    manifest = pkgs.fetchurl {
      name = "kpack-manifest";
      url = "https://github.com/pivotal/kpack/releases/download/v0.9.2/release-0.9.2.yaml";
      sha256 = "sha256-oU/QiF/QUlmVez/C5FZr2K8dLTmvFvErWEnzgSAda04=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    name = "kpack";
    version = "1.0.0";

    phases = ["installPhase"];

    installPhase = ''
      mkdir --parents $out/bin $out/share

      install --verbose ${kpack.cli} $out/bin/kp
      install --verbose ${kpack.manifest} $out/share/kpack.yaml
    '';

    meta = {
      description = "Kubernetes Native Container Build Service";
      homepage = "https://github.com/pivotal/kpack";
      license = "Apache 2.0";
    };
  }

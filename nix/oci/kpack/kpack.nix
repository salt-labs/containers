{
  pkgs,
  ...
}:
let
  kpack = {
    cli = pkgs.fetchurl {
      name = "kpack-cli";
      version = "0.17.2";
      url = "https://github.com/buildpacks-community/kpack-cli/releases/download/v${kpack.cli.version}/kp-linux-amd64-${kpack.cli.version}";
      sha256 = "sha256-pWVQSo72ELFtp7u4YF9eB7vIUY08fgAdVu0AAgt6B34=";
    };

    manifest = pkgs.fetchurl {
      name = "kpack-manifest";
      version = "0.18.0";
      url = "https://github.com/pivotal/kpack/releases/download/v${kpack.manifest.version}/release-${kpack.manifest.version}.yaml";
      sha256 = "sha256-zei3340x1qV1jsSIDuxFAJ8XgRuvPfWim3ahRP4gDmk=";
    };
  };
in
pkgs.stdenv.mkDerivation {
  name = "kpack";
  version = "1.0.0";

  phases = [ "installPhase" ];

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

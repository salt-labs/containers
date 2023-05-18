{
  pkgs,
  crossPkgs,
  ...
}: let
  carvel = {
    ytt = pkgs.fetchurl {
      name = "ytt";
      url = "https://github.com/carvel-dev/ytt/releases/download/v0.45.1/ytt-linux-amd64";
      sha256 = "sha256-AWBtiFzbzgI0D6rcKag7VBUoC8YQ58/z9jk4XY9QSuo=";
    };

    kapp = pkgs.fetchurl {
      name = "kapp";
      url = "https://github.com/carvel-dev/kapp/releases/download/v0.56.0/kapp-linux-amd64";
      sha256 = "sha256-J2Sqw4Q1sReKnCMsBytuGEv8iAImhYCrkRoehO68QsE=";
    };

    kapp-controller = pkgs.fetchurl {
      name = "kctrl";
      url = "https://github.com/carvel-dev/kapp-controller/releases/download/v0.45.1/kctrl-linux-amd64";
      sha256 = "sha256-hlov/BCjJZfPAmZWOCgp6bM7tC9V+tcDOLTFmqXeM+U=";
    };

    kbld = pkgs.fetchurl {
      name = "kbld";
      url = "https://github.com/carvel-dev/kbld/releases/download/v0.37.1/kbld-linux-amd64";
      sha256 = "sha256-8y+xJR/Ltw0ZJUIQUETFKRxuZ/vKf7Rnvw042Sub8gQ=";
    };

    imgpkg = pkgs.fetchurl {
      name = "imgpkg";
      url = "https://github.com/carvel-dev/imgpkg/releases/download/v0.36.2/imgpkg-linux-amd64";
      sha256 = "sha256-VpaXZr+yN5esmCXhtXgiFf7gtMbyinuBlrq+TT7Fw2U=";
    };

    vendir = pkgs.fetchurl {
      name = "vendir";
      url = "https://github.com/carvel-dev/vendir/releases/download/v0.33.2/vendir-linux-amd64";
      sha256 = "sha256-LMj42zF2hffScCZHErsx77/eFOlbBl8xzR4tjJ7rLTQ=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    name = "carvel-dev";
    version = "1.1.0";

    phases = ["installPhase"];

    installPhase = ''
      mkdir --parents $out/bin

      install --verbose ${carvel.ytt} $out/bin/ytt
      install --verbose ${carvel.kapp} $out/bin/kapp
      install --verbose ${carvel.kapp-controller} $out/bin/kctrl
      install --verbose ${carvel.kbld} $out/bin/kbld
      install --verbose ${carvel.imgpkg} $out/bin/imgpkg
      install --verbose ${carvel.vendir} $out/bin/vendir
    '';

    meta = {
      description = "Carvel provides a set of reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes.";
      homepage = "https://carvel.dev";
      license = "Apache 2.0";
    };
  }

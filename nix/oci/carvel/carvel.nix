{
  pkgs,
  crossPkgs,
  ...
}: let
  carvel = {
    ytt = pkgs.fetchurl {
      name = "ytt";
      url = "https://github.com/carvel-dev/ytt/releases/download/v0.46.2/ytt-linux-amd64";
      sha256 = "sha256-rpvGalV1bu1g24b4wPjFVwSzq4RlE61FAhEcKoZz7Kw=";
    };

    kapp = pkgs.fetchurl {
      name = "kapp";
      url = "https://github.com/carvel-dev/kapp/releases/download/v0.59.1/kapp-linux-amd64";
      sha256 = "sha256-pto0xzNRTCxRuWoS5wzQUCUKRbLuddaWapBOcSswfRU=";
    };

    kctrl = pkgs.fetchurl {
      name = "kctrl";
      url = "https://github.com/carvel-dev/kapp-controller/releases/download/v0.49.0/kctrl-linux-amd64";
      sha256 = "sha256-7UeEeFADnPVXKvSUINA2WyzGijpzH7xeiiOxPrj/sCA=";
    };

    kbld = pkgs.fetchurl {
      name = "kbld";
      url = "https://github.com/carvel-dev/kbld/releases/download/v0.38.1/kbld-linux-amd64";
      sha256 = "sha256-AOEUKGWIMH0HhcS/sbuPaKzKHqGG63nNhHUhQhRBMpE=";
    };

    imgpkg = pkgs.fetchurl {
      name = "imgpkg";
      url = "https://github.com/carvel-dev/imgpkg/releases/download/v0.39.0/imgpkg-linux-amd64";
      sha256 = "sha256-mLgLql1mXFEZ/I4qYpePnRk8lkfjxHq3KGewVblNFP8=";
    };

    vendir = pkgs.fetchurl {
      name = "vendir";
      url = "https://github.com/carvel-dev/vendir/releases/download/v0.37.0/vendir-linux-amd64";
      sha256 = "sha256-8Ucr95lVBoMPp5Rz8K5AbqOIXgiB+7sJYkDvsbBT3RU=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    name = "carvel-dev";
    version = "1.2.0";

    phases = ["installPhase"];

    installPhase = ''
      mkdir --parents $out/usr/local/bin

      install --verbose ${carvel.ytt} $out/usr/local/bin/ytt
      install --verbose ${carvel.kapp} $out/usr/local/bin/kapp
      install --verbose ${carvel.kctrl} $out/usr/local/bin/kctrl
      install --verbose ${carvel.kbld} $out/usr/local/bin/kbld
      install --verbose ${carvel.imgpkg} $out/usr/local/bin/imgpkg
      install --verbose ${carvel.vendir} $out/usr/local/bin/vendir
    '';

    meta = {
      description = "Carvel provides a set of reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes.";
      homepage = "https://carvel.dev";
      license = "Apache 2.0";
    };
  }

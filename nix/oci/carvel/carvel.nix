{
  pkgs,
  crossPkgs,
  ...
}: let
  carvel = {
    ytt = pkgs.fetchurl {
      name = "ytt";
      url = "https://github.com/carvel-dev/ytt/releases/download/v0.46.0/ytt-linux-amd64";
      sha256 = "sha256-NIyzSWW2TAf9URjmnv2aT65+IvV9tOkeLZkDwa0Z8EE=";
    };

    kapp = pkgs.fetchurl {
      name = "kapp";
      url = "https://github.com/carvel-dev/kapp/releases/download/v0.59.0/kapp-linux-amd64";
      sha256 = "sha256-zBzKeDFzut1edO3B8Q3s/K6FUlz+znOz1DrP2h6sy+U=";
    };

    kctrl = pkgs.fetchurl {
      name = "kctrl";
      url = "https://github.com/carvel-dev/kapp-controller/releases/download/v0.48.1/kctrl-linux-amd64";
      sha256 = "sha256-xtMi7ZUN3GESwdHbof7qvCTyIuSiTey6LWDAJAMZRAY=";
    };

    kbld = pkgs.fetchurl {
      name = "kbld";
      url = "https://github.com/carvel-dev/kbld/releases/download/v0.38.0/kbld-linux-amd64";
      sha256 = "sha256-xuzy02t6cvK6tX+uKm6KKohsKwByOIqffdBzY/wPE/w=";
    };

    imgpkg = pkgs.fetchurl {
      name = "imgpkg";
      url = "https://github.com/carvel-dev/imgpkg/releases/download/v0.38.0/imgpkg-linux-amd64";
      sha256 = "sha256-Pycvx+rLEpqYm49obqWUVat+ZUIxkoA8Fdav+5Y/hqk=";
    };

    vendir = pkgs.fetchurl {
      name = "vendir";
      url = "https://github.com/carvel-dev/vendir/releases/download/v0.35.0/vendir-linux-amd64";
      sha256 = "sha256-2RCfuPB77auCC2DkeJorGDhXBz+jks1gO5yr6seVugQ=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    name = "carvel-dev";
    version = "1.1.0";

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

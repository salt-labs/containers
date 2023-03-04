{pkgs, ...}: let
  carvel = {
    ytt = pkgs.fetchurl {
      name = "ytt";
      url = "https://github.com/carvel-dev/ytt/releases/download/v0.40.4/ytt-linux-amd64";
      sha256 = "sha256-LLpey2AtwrzKr9iTB3pm3svfl30XtjOWcnhmjpXUjfs=";
    };

    kapp = pkgs.fetchurl {
      name = "kapp";
      url = "https://github.com/carvel-dev/kapp/releases/download/v0.54.3/kapp-linux-amd64";
      sha256 = "sha256-a1Pg2Gb7PNy3gUdcI5c+q2w3lZ5TwiCUvIH5mIhNdK4=";
    };

    kctrl = pkgs.fetchurl {
      name = "kctrl";
      url = "https://github.com/carvel-dev/kapp-controller/releases/download/v0.40.0/kctrl-linux-amd64";
      sha256 = "sha256-FqXD5/9J1S5hadSlf6v56GLW6vfnuHKTunNquURogDQ=";
    };

    kbld = pkgs.fetchurl {
      name = "kbld";
      url = "https://github.com/carvel-dev/kbld/releases/download/v0.36.4/kbld-linux-amd64";
      sha256 = "sha256-apM/p2qlgbbJLIEMTDWHf61oGH4ukyC4aHbgDsaFIYU=";
    };

    imgpkg = pkgs.fetchurl {
      name = "imgpkg";
      url = "https://github.com/carvel-dev/imgpkg/releases/download/v0.35.0/imgpkg-linux-amd64";
      sha256 = "sha256-LCic9rXIik3UvsF8nlfknCx1McEn6hMHN5RTks3GU2I=";
    };

    vendir = pkgs.fetchurl {
      name = "vendir";
      url = "https://github.com/carvel-dev/vendir/releases/download/v0.32.5/vendir-linux-amd64";
      sha256 = "sha256-DYpF0thWR86TLh1jDUlmjpZVIUCtM8atrV9Ym7gAu4o=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    name = "carvel-dev";
    version = "1.0.0";

    phases = ["installPhase"];

    installPhase = ''
      mkdir --parents $out/bin

      install --verbose ${carvel.ytt} $out/bin/ytt
      install --verbose ${carvel.kapp} $out/bin/kapp
      install --verbose ${carvel.kctrl} $out/bin/kctrl
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

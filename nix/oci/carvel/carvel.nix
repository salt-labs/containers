{
  pkgs,
  crossPkgs,
  ...
}: let
  versions = {
    imgpkg = "v0.41.1";
    kapp = "v0.60.0";
    kbld = "v0.41.0";
    kctrl = "v0.50.0";
    kwt = "v0.0.8";
    vendir = "v0.40.0";
    ytt = "v0.48.0";
  };

  carvel = {
    # imgpkg
    imgpkg = pkgs.fetchurl {
      name = "imgpkg";
      url = "https://github.com/carvel-dev/imgpkg/releases/download/${versions.imgpkg}/imgpkg-linux-amd64";
      sha256 = "sha256-5ikTCb4nTYE3EWu6BoJK92PiIRDUjpzEWsoNMTVCCWY=";
    };

    # kapp
    kapp = pkgs.fetchurl {
      name = "kapp";
      url = "https://github.com/carvel-dev/kapp/releases/download/${versions.kapp}/kapp-linux-amd64";
      sha256 = "sha256-fMF5cWNNppyA1xWRmcLFFMOLR50omH4FXOLBc7+9kwY=";
    };

    # kbld
    kbld = pkgs.fetchurl {
      name = "kbld";
      url = "https://github.com/carvel-dev/kbld/releases/download/${versions.kbld}/kbld-linux-amd64";
      sha256 = "sha256-iwD6agd0ltIQ2xsvRQl/yJGnfFZTQr71YYRX0d426DQ=";
    };

    # kctrl
    kctrl = pkgs.fetchurl {
      name = "kctrl";
      url = "https://github.com/carvel-dev/kapp-controller/releases/download/${versions.kctrl}/kctrl-linux-amd64";
      sha256 = "sha256-YXpOOtLiR/6wmFcIbXlgZdrU33PLgdxZ0ap7+kqa/wc=";
    };

    # kwt
    kwt = pkgs.fetchurl {
      name = "kwt";
      url = "https://github.com/carvel-dev/kwt/releases/download/${versions.kwt}/kwt-linux-amd64";
      sha256 = "sha256-ECJIOotZ/iOOeCqROPH+5sph7PfM0eXw2Y6VxW35TYc=";
    };

    # vendir
    vendir = pkgs.fetchurl {
      name = "vendir";
      url = "https://github.com/carvel-dev/vendir/releases/download/${versions.vendir}/vendir-linux-amd64";
      sha256 = "sha256-PgdqRS2I1uO8GQ1Sf018lJq27Mrhm/XTy7kQ1Tck8rk=";
    };

    # ytt
    ytt = pkgs.fetchurl {
      name = "ytt";
      url = "https://github.com/carvel-dev/ytt/releases/download/${versions.ytt}/ytt-linux-amd64";
      sha256 = "sha256-CQ3JFMh+W6WGHjf4hfErrDsVVZwYPDDUry5jzKsD1fk=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    name = "carvel-dev";
    version = "1.2.0";

    phases = ["installPhase"];

    installPhase = ''
      mkdir --parents $out/usr/local/bin

      install --verbose ${carvel.imgpkg} $out/usr/local/bin/imgpkg
      install --verbose ${carvel.kapp} $out/usr/local/bin/kapp
      install --verbose ${carvel.kbld} $out/usr/local/bin/kbld
      install --verbose ${carvel.kctrl} $out/usr/local/bin/kctrl
      install --verbose ${carvel.kwt} $out/usr/local/bin/kwt
      install --verbose ${carvel.vendir} $out/usr/local/bin/vendir
      install --verbose ${carvel.ytt} $out/usr/local/bin/ytt
    '';

    meta = {
      description = "Carvel provides a set of reliable, single-purpose, composable tools that aid in your application building, configuration, and deployment to Kubernetes.";
      homepage = "https://carvel.dev";
      license = "Apache 2.0";
    };
  }

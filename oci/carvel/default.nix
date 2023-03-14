{
  pkgs,
  crossPkgs,
  ...
}: let
  carvel = pkgs.callPackage ./carvel.nix {
    inherit pkgs;
    inherit crossPkgs;
  };
in
  pkgs.dockerTools.buildImage {
    name = "carvel";
    tag = "latest";
    #created = "now";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = ["/bin"];

      paths = with pkgs; [
        # Common
        busybox
        curlFull
        cacert

        # Tools
        carvel
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "Carvel";
      };
      Entrypoint = [
        "${pkgs.busybox}/bin/sh"
      ];
      Cmd = [
      ];
      ExposedPorts = {
      };
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
      WorkingDir = "/workdir";
    };
  }

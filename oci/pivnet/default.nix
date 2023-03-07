{
  pkgs,
  crossPkgs,
  ...
}: let
  pivnet = pkgs.callPackage ./pivnet.nix {
    inherit pkgs;
    inherit crossPkgs;
  };
in
  pkgs.dockerTools.buildImage {
    name = "pivnet";
    tag = "latest";
    created = "now";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = ["/bin"];

      paths = with pkgs; [
        # Common
        busybox
        curlFull
        cacert

        # Tools
        pivnet
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "pivnet";
      };
      Entrypoint = [
        "${pivnet}/bin/pivnet"
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

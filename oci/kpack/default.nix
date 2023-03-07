{
  pkgs,
  crossPkgs,
  ...
}: let
  kpack = pkgs.callPackage ./kpack.nix {
    inherit pkgs;
    inherit crossPkgs;
  };
in
  pkgs.dockerTools.buildImage {
    name = "kpack";
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
        kpack
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "kpack";
      };
      Entrypoint = [
        "/bin/kp"
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

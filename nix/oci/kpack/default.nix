{
  pkgs,
  crossPkgs,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  kpack = pkgs.callPackage ./kpack.nix {
    inherit pkgs;
    inherit crossPkgs;
  };
in
  pkgs.dockerTools.buildImage {
    name = "kpack";
    tag = "latest";
    created = creationDate;

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

{
  pkgs,
  crossPkgs,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;
in
  pkgs.dockerTools.buildImage {
    name = "snyk";
    tag = "latest";
    # created = creationDate;

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = ["/bin"];

      paths = with pkgs; [
        # Common
        busybox
        curlFull
        cacert

        # Tools
        nodePackages.snyk
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "snyk";
      };
      Entrypoint = [
        "${pkgs.nodePackages.snyk}/bin/snyk"
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

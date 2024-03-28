{
  pkgs,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;
in
  pkgs.dockerTools.buildImage {
    name = "kubectl";
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
        kubectl
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "kubectl";
      };
      Entrypoint = [
        "${pkgs.kubectl}/bin/kubectl"
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

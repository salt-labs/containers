{
  pkgs,
  crossPkgs,
  self,
  ...
}: let
  lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 lastModifiedDate;
in
  pkgs.dockerTools.buildImage {
    name = "govc";
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
        govc
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "govc";
      };
      Entrypoint = [
        "${pkgs.govc}/bin/govc"
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

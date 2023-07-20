{
  pkgs,
  pkgsUnstable,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  entrypoint = pkgs.callPackage ./entrypoint {};

  unstablePkgs = with pkgsUnstable; [
    caddy
  ];
in
  pkgs.dockerTools.buildImage {
    name = "caddy";
    tag = "latest";
    # created = creationDate;

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = ["/bin"];

      paths = with pkgs;
        [
          # Common
          busybox
          curlFull
          cacert
          git
        ]
        ++ unstablePkgs;
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "Caddy";
      };
      Entrypoint = [
        "${entrypoint}/bin/entrypoint"
      ];
      Cmd = [
      ];
      ExposedPorts = {
        "80/tcp" = {};
        "443/tcp" = {};
      };
      Env = [
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      ];
      WorkingDir = "/workdir";
    };
  }

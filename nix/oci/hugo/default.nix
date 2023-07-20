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
    hugo
  ];
in
  pkgs.dockerTools.buildImage {
    name = "hugo";
    tag = "latest";
    created = creationDate;

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
        "org.opencontainers.image.description" = "Hugo";
      };
      Entrypoint = [
        "${entrypoint}/bin/entrypoint"
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

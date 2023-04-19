{
  pkgs,
  pkgsUnstable,
  ...
}: let
  entrypoint = pkgs.callPackage ./entrypoint {};

  unstablePkgs = with pkgsUnstable; [
    caddy
  ];
in
  pkgs.dockerTools.buildImage {
    name = "caddy";
    tag = "latest";
    #created = "now";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = ["/bin"];

      paths = with pkgs;
        [
          # Common
          busybox
          curlFull
          cacert
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

#########################
# References:
#       https://ryantm.github.io/nixpkgs/builders/images/dockertools/
#       https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix
#########################
{
  pkgs,
  pkgLoopy,
  ...
}: let
  app = pkgLoopy;
in
  pkgs.dockerTools.buildImage {
    name = "loopy";
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
        ++ [
          # Tools
          app
        ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "DESCRIPTION";
      };
      Entrypoint = [
        "${app}/bin/loopy"
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

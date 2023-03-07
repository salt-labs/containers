{
  pkgs,
  crossPkgs,
  ...
}: let
  tanzu = pkgs.callPackage ./tanzu.nix {
    inherit pkgs;
    inherit crossPkgs;
  };
in
  pkgs.dockerTools.buildImage {
    name = "tanzu";
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
        tanzu
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "tanzu";
      };
      Entrypoint = [
        "${tanzu}/bin/tanzu"
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

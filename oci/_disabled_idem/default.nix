{pkgs, ...}: let
  idem = pkgs.callPackage ./idem.nix {};
in
  pkgs.dockerTools.buildImage {
    name = "idem";
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
        idem
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "Idem";
      };
      Entrypoint = [
        #"${idem}/bin/python"
        "${pkgs.busybox}/bin/sh"
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

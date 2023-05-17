{
  pkgs,
  crossPkgs,
  ...
}: let
  tanzu_1 = pkgs.callPackage ./tanzu_1.nix {
    inherit pkgs;
    inherit crossPkgs;
  };

  tanzu_2 = pkgs.callPackage ./tanzu_2.nix {
    inherit pkgs;
    inherit crossPkgs;
  };

  tanzu = pkgs.writeShellScriptBin "tanzu" ''
    #!/bin/sh
    /bin/tanzu-2.1.0 "$@"
  '';
in
  pkgs.dockerTools.buildImage {
    name = "tanzu";
    tag = "latest";
    #created = "now";

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
        tanzu_1
        tanzu_2
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "tanzu";
      };
      Entrypoint = [
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

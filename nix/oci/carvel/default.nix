{
  pkgs,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  carvel = pkgs.callPackage ./carvel.nix {
    inherit pkgs;
  };
in
  pkgs.dockerTools.buildImage {
    name = "carvel";
    tag = "latest";
    # created = creationDate;

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = [
        "/bin"
        "/tmp"
        "/home"
        "/workdir"
        "/github"
      ];

      paths = with pkgs; [
        # Common
        busybox
        curlFull
        cacert

        # Tools
        clusterctl
        kail
        kube-bench
        kube-linter
        kubectl
        kubernetes-helm
        kustomize
        kustomize-sops
        sonobuoy
        sops
        velero

        # Carvel
        carvel
      ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "Carvel";
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

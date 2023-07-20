{
  nixpkgs,
  pkgs,
  system,
  poetry2nix,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  overlay = self: super: {
    app = self.poetry2nix.mkPoetryApplication {
      projectDir = ./poetry;
      inherit system;
      inherit poetry2nix;
    };
  };

  overlayPkgs = import nixpkgs {
    inherit system;
    overlays = [overlay];
  };
in
  pkgs.dockerTools.buildImage {
    name = "idem";
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
        ]
        ++ [
          # Tools
          overlayPkgs.app
        ];
    };

    config = {
      Labels = {
        "org.opencontainers.image.description" = "Idem";
      };
      Entrypoint = [
        "${overlayPkgs.app}/bin/entrypoint"
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

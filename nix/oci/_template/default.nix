#########################
# References:
#       https://ryantm.github.io/nixpkgs/builders/images/dockertools/
#       https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix
#########################
{
  nixpkgs,
  pkgs,
  system,
  poetry2nix,
  self,
  ...
}: let
  lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 lastModifiedDate;

  #app = pkgs.callPackage ./poetry {
  #  inherit pkgs;
  #  inherit system;
  #  inherit poetry2nix;
  #};
  overlay = self: super: {
    app = self.poetry2nix.mkPoetryApplication {
      projectDir = ./poetry;
      python = pkgs.python3;
      poetry = poetry2nix;
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
    name = "template";
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
        "org.opencontainers.image.description" = "DESCRIPTION";
      };
      Entrypoint = [
        "${overlayPkgs.app}/bin/entrypoint"
        #"${pkgs.template}/bin/template"
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

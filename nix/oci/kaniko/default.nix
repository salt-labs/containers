{
  pkgs,
  pkgsUnstable,
  crossPkgs,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  unstablePkgs = with pkgsUnstable; [
    kaniko
  ];

  environmentHelpers = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
    fakeNss
  ];
  #kaniko = pkgs.callPackage ./kaniko.nix {
  #  stdenv = pkgs.stdenv;
  #  lib = pkgs.lib;
  #  fetchFromGitHub = pkgs.fetchFromGitHub;
  #  buildGoModule = pkgs.buildGoModule;
  #  installShellFiles = pkgs.installShellFiles;
  #  testers = pkgs.testers;
  #};
in
  pkgs.dockerTools.buildLayeredImage {
    name = "kaniko";
    tag = "latest";
    # created = creationDate;

    #fromImage = baseImage;
    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = [
        "/bin"
        "/etc"
        "/root"
        "/run"
        "/tmp"
      ];

      paths = with pkgs;
        [
          bash
          bash-completion
          cacert
          coreutils-full
          docker-credential-gcr
          docker-credential-helpers
          #kaniko
        ]
        ++ unstablePkgs
        ++ environmentHelpers;
    };

    enableFakechroot = true;

    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      # Kaniko
      # https://github.com/GoogleContainerTools/kaniko/blob/main/deploy/Dockerfile#L52-L56
      mkdir --parents /kaniko/.docker /kaniko/ssl/certs
      touch /kaniko/.docker/config.json
      chmod -r 777 /kaniko/
      cat /etc/ssl/certs/ca-bundle.crt >> /kaniko/ssl/certs/additional-ca-cert-bundle.crt
    '';

    config = {
      Labels = {
        "org.opencontainers.image.description" = "Kaniko";
      };
      Entrypoint = [
        #"${kaniko}/bin/executor"
        "${pkgsUnstable.kaniko}/bin/executor"
      ];
      Cmd = [
      ];
      ExposedPorts = {
      };
      Env = [
        "DOCKER_CONFIG=/kaniko/.docker/"
        "DOCKER_CREDENTIAL_GCR_CONFIG=/kaniko/.config/gcloud/docker_credential_gcr_config.json"
        "HOME=/root"
        "PATH=/bin:/kaniko"
        "SSL_CERT_DIR=/kaniko/ssl/certs"
        "USER=root"
        "WORKDIR=/workspace"
      ];
      WorkingDir = "/workspace";
    };
  }

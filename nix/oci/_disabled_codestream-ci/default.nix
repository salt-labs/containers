{
  pkgs,
  pkgsUnstable,
  crossPkgs,
  pkgCodestreamCLI,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  containerUser = "codestream-ci";

  entrypoint = pkgs.callPackage ./entrypoint {};

  environmentHelpers = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
    fakeNss
  ];

  baseImage = pkgs.dockerTools.buildImageWithNixDb {
    name = "docker.io/debian";
    tag = "stable-slim";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = [
        "/bin"
        "/home"
        "/var"
      ];
      paths = with pkgs; [
        bash
        coreutils
        nix
      ];
    };
    config = {
      Env = [
        "NIX_PAGER=cat"
        "USER=nobody"
      ];
    };
  };

  nonRootShadowSetup = {
    user,
    uid,
    gid ? uid,
  }:
    with pkgs; [
      (
        writeTextDir "etc/shadow" ''
          root:!x:::::::
          ${user}:!:::::::
        ''
      )
      (
        writeTextDir "etc/passwd" ''
          root:x:0:0::/root:${runtimeShell}
          ${user}:x:${toString uid}:${toString gid}::/home/${user}:
        ''
      )
      (
        writeTextDir "etc/group" ''
          root:x:0:
          ${user}:x:${toString gid}:
        ''
      )
      (
        writeTextDir "etc/gshadow" ''
          root:x::
          ${user}:x::
        ''
      )
    ];

  unstablePkgs = with pkgsUnstable; [
    kaniko
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "codestream-ci";
    tag = "latest";
    created = creationDate;

    #fromImage = baseImage;
    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = [
        "/bin"
        "/etc"
        "/home"
        "/lib"
        "/root"
        "/run"
        "/sbin"
        "/usr"
        "/var"
        "/tmp"
        "/workdir"
      ];

      paths = with pkgs;
        [
          # Common
          bashInteractive
          bash-completion
          cacert
          coreutils-full
          curlFull
          findutils
          getopt
          git
          gnutar
          gzip
          jq
          less
          libcap
          ncurses
          readline
          sudo
          shadow
          tree
          tzdata
          unzip
          vim
          which
          wget
          yq

          # Everything including the kitchen sink.
          brakeman
          buildah
          clair
          clamav
          cosign
          docker-credential-gcr
          docker-credential-helpers
          flawfinder
          gitleaks
          gosec
          govc
          grype
          hadolint
          helm
          kics
          kube-linter
          kubectl
          kubesec
          license_finder
          nodePackages.snyk
          packer
          pandoc
          safety-cli
          secretscanner
          semgrep
          shellcheck
          skopeo
          sonar-scanner-cli
          syft
          tflint
          tfsec
          trivy

          # Python
          python310
          python310Packages.bandit

          # Entrypoint
          entrypoint

          # Codestream CLI
          #pkgCodestreamCLI
        ]
        ++ unstablePkgs
        ++ environmentHelpers; #++ nonRootShadowSetup { uid = 1000; user = "codestream-ci"; };
    };

    enableFakechroot = true;

    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      ${pkgs.dockerTools.shadowSetup}

      # Kaniko
      # https://github.com/GoogleContainerTools/kaniko/blob/main/deploy/Dockerfile#L52-L56
      mkdir --parents /kaniko/.docker /kaniko/ssl/certs
      touch /kaniko/.docker/config.json
      chmod -r 777 /kaniko/
      cat /etc/ssl/certs/ca-bundle.crt >> /kaniko/ssl/certs/additional-ca-cert-bundle.crt
    '';

    config = {
      User = containerUser;
      Labels = {
        "org.opencontainers.image.description" = "Codestream CI";
      };
      Entrypoint = [
        #"${entrypoint}/bin/codestream-ci"
        "${entrypoint}/bin/bash"
      ];
      Cmd = [
      ];
      ExposedPorts = {
      };
      Env = [
        "CHARSET=UTF-8"
        "DOCKER_CONFIG=/kaniko/.docker/"
        "DOCKER_CREDENTIAL_GCR_CONFIG=/kaniko/.config/gcloud/docker_credential_gcr_config.json"
        "HOME=/root"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        #"PS1='🐳  \[\033[1;36m\]\h \[\033[1;34m\]\W\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'"
        "PATH=/bin:/kaniko"
        "SHELL=/bin/bash"
        "SSL_CERT_DIR=/kaniko/ssl/certs"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm"
        "TZ=UTC"
        "USER=root"
        "WORKDIR=/workdir"
      ];
      WorkingDir = "/workdir";
    };
  }

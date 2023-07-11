{
  pkgs,
  crossPkgs,
  ...
}: let
  containerUser = "tanzu";

  tanzu = pkgs.callPackage ./tanzu.nix {
    inherit pkgs;
    inherit crossPkgs;
  };

  carvel = pkgs.callPackage ./carvel.nix {
    inherit pkgs;
    inherit crossPkgs;
  };

  environmentHelpers = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
    shadowSetup
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu";
    tag = "latest";
    #created = "now";

    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/bin"
        "/etc"
        "/github"
        "/home"
        "/lib"
        "/root"
        "/run"
        "/sbin"
        "/tmp"
        "/usr"
        "/var"
        "/workdir"
      ];

      paths = with pkgs;
        [
          # Common
          bash-completion
          bashInteractive
          cacert
          coreutils-full
          curlFull
          figlet
          getent
          git
          gnugrep
          gnutar
          gzip
          jq
          less
          ripgrep
          shadow
          starship
          su
          tree
          unzip
          wget
          which
          yq

          # Docker Tools
          dive
          docker
          docker-buildx
          docker-gc
          docker-ls

          # Kubernetes Tools
          clusterctl
          kail
          kapp
          kube-bench
          kube-linter
          kubectl
          kubernetes-helm
          kustomize
          kustomize-sops
          sonobuoy
          sops
          velero
          vendir
          ytt

          # Custom derivations
          carvel
          tanzu
        ]
        ++ environmentHelpers;
    };

    enableFakechroot = true;

    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      ${pkgs.dockerTools.shadowSetup}

      cat << EOF > /etc/os-release
      BUG_REPORT_URL="https://github.com/NixOS/nixpkgs/issues"
      BUILD_ID="container"
      DOCUMENTATION_URL="https://nixos.org/learn.html"
      HOME_URL="https://nixos.org/"
      ID=nixos
      LOGO="nix-snowflake"
      NAME=NixOS
      PRETTY_NAME="NixOS"
      SUPPORT_END="Unknown"
      SUPPORT_URL="https://nixos.org/community.html"
      VERSION="container"
      VERSION_CODENAME=container
      VERSION_ID="container"
      EOF

      groupadd \
        ${containerUser} || {
          echo "Failed to create group ${containerUser}"
          exit 1
        }

      groupadd \
        docker || {
          echo "Failed to create group docker"
          exit 1
        }

      useradd \
        --home-dir /home/${containerUser} \
        --shell ${pkgs.bashInteractive}/bin/bash \
        --create-home \
        --user-group \
        --groups docker \
        ${containerUser} || {
          echo "Failed to create user ${containerUser}"
          exit 1
        }

      cat << EOF > /home/${containerUser}/.bashrc
      eval "\$(starship init bash)"
      tanzu plugin clean || {
        echo "Failed to clean the Tanzu CLI plugins"
      }
      tanzu init || {
        echo "Failed to initialise the Tanzu CLI. Please check network connectivbity and try again."
      }
      figlet "Tanzu CLI"
      EOF
      chmod 0777 /home/${containerUser}/.bashrc

      chmod --verbose --recursive 777 /workdir || exit 1
      chmod --verbose --recursive 777 /tmp || exit 1
    '';

    config = {
      User = containerUser;
      Labels = {
        "org.opencontainers.image.description" = "tanzu";
      };
      Entrypoint = [
        "${pkgs.bashInteractive}/bin/bash"
      ];
      Cmd = [
      ];
      ExposedPorts = {
      };
      Env = [
        "CHARSET=UTF-8"
        "DOCKER_CONFIG=/home/${containerUser}/.docker"
        "HOME=/home/${containerUser}"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "PATH=/sbin:/bin:/workdir"
        "SHELL=${pkgs.bashInteractive}"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm"
        "TZ=UTC"
        "USER=${containerUser}"
        "WORKDIR=/workdir"
      ];
      WorkingDir = "/workdir";
    };
  }

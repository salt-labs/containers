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
    #fakeNss
    shadowSetup
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu";
    tag = "latest";
    #created = "now";

    maxLayers = 25;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/bin"
        "/etc"
        "/home"
        "/root"
        "/var"
      ];

      paths = with pkgs;
        [
          # Common
          bash-completion
          bashInteractive
          cacert
          coreutils-full
          curlFull
          diffutils
          figlet
          gawk
          git
          gnupg
          gnugrep
          gnused
          gnutar
          gzip
          jq
          less
          openssh
          procps
          ripgrep
          shadow
          starship
          su
          tree
          unzip
          wget
          which
          xz
          yq

          # VSCode
          findutils
          gcc-unwrapped
          glibc
          iproute

          # Docker Tools
          #dive
          #docker
          #docker-buildx
          #docker-gc
          #docker-ls

          # Kubernetes Tools
          #clusterctl
          #kail
          #kapp
          #kube-bench
          #kube-linter
          #kubectl
          #kubernetes-helm
          #kustomize
          #kustomize-sops
          #sonobuoy
          #sops
          #velero
          #vendir
          #ytt

          # Custom derivations
          #carvel
          #tanzu
        ]
        ++ environmentHelpers;
    };

    # Enable fakeRootCommands in fakechroot
    enableFakechroot = true;

    # Run these commands in fakechroot
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      ${pkgs.dockerTools.shadowSetup}

      # Create /etc/os-release
      cat << EOF > /etc/os-release
      NAME="SaltOS"
      VERSION_ID="1"
      VERSION="1"
      VERSION_CODENAME="base"
      ID=saltos
      HOME_URL="https://www.saltlabs.tech/"
      SUPPORT_URL="https://www.saltlabs.tech/"
      BUG_REPORT_URL="https://github.com/salt-labs/containers/issues"
      EOF

      # VSCode includes a bundled nodejs binary which is
      # dynamically linked and hardcoded to look in /lib
      ln -s ${pkgs.glibc}/lib /lib
      ln -s ${pkgs.gcc-unwrapped.lib}/lib64 /lib64

      # Create users and groups
      groupadd docker || {
        echo "Failed to create group docker"
        exit 1
      }

      # Create a container user
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

      # Create a user for vscode devcontainers
      useradd \
        --home-dir /home/vscode \
        --shell ${pkgs.bashInteractive}/bin/bash \
        --create-home \
        --user-group \
        --groups docker \
        vscode || {
          echo "Failed to create user vscode"
          exit 1
        }

      # Setup the .bashrc for the container user.
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

      # Set permissions on required directories
      mkdir --parents --mode 0777 /tmp || exit 1
      mkdir --parents --mode 0777 /workdir || exit 1
      mkdir --parents --mode 0777 /workspace || exit 1
      mkdir --parents --mode 0777 /vscode || exit 1
      mkdir --parents --mode 0777 /var/devcontainer || exit 1
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
    '';

    /*
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      ${pkgs.dockerTools.shadowSetup}

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

      chmod --verbose --recursive 0777 /home/${containerUser} || exit 1
      chmod --verbose --recursive 0777 /workdir /workspace || exit 1
      chmod --verbose --recursive 1777 /tmp || exit 1
    '';

    */

    config = {
      User = containerUser;
      Labels = {
        "org.opencontainers.image.description" = "tanzu";
      };
      Entrypoint = [
        #"${pkgs.bashInteractive}/bin/bash"
      ];
      Cmd = [
        "${pkgs.bashInteractive}/bin/bash"
      ];
      ExposedPorts = {
      };
      Env = [
        "CHARSET=UTF-8"
        "DOCKER_CONFIG=/home/${containerUser}/.docker"
        "HOME=/home/${containerUser}"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib;${pkgs.gcc-unwrapped.lib}/lib64"
        "PAGER=less"
        "NIX_PAGER=less"
        "PATH=/workdir:/usr/bin:/bin:/sbin"
        "SHELL=${pkgs.bashInteractive}/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm"
        "TZ=UTC"
        "USER=${containerUser}"
        "WORKDIR=/workdir"
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/vscode" = {};
      };
    };
  }

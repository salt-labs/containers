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
        "/lib"
        "/lib64"
        "/usr"
      ];

      paths = with pkgs;
        [
          # Common
          bash-completion
          bashInteractive
          bat
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
          htop
          jq
          less
          ncurses
          openssh
          procps
          ripgrep
          shadow
          starship
          su
          tree
          unzip
          vim
          wget
          which
          xz
          yq-go

          # VSCode
          findutils
          gcc-unwrapped
          glibc
          iproute

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
      ln -s ${pkgs.stdenv.cc.cc.lib}/lib /lib/stdenv
      ln -s ${pkgs.glibc}/lib /lib/glibc
      ln -s ${pkgs.stdenv.cc.cc.lib}/lib64 /lib64/stdenv
      ln -s ${pkgs.glibc}/lib64 /lib64/glibc
      ln -s /lib64/glibc/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2

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
      source <(/bin/starship init bash --print-full-init)
      echo "Initialising Tanzu CLI..."
      tanzu plugin clean || {
        echo "Failed to clean the Tanzu CLI plugins"
      }
      tanzu init || {
        echo "Failed to initialise the Tanzu CLI. Please check network connectivbity and try again."
      }
      figlet "Tanzu CLI"
      EOF

      # Setup the .bashrc for the vscode user.
      cat << 'EOF' > "/home/vscode/.bashrc"
      source <(/bin/starship init bash --print-full-init)
      if [[ "''${VSCODE:-FALSE}" == "TRUE" ]];
      then
        while true;
        do
          clear
          read -p "Initialise the Tanzu CLI? y/n: " CHOICE
          case $CHOICE in
            [Yy]* )
              echo "Initialising Tanzu CLI..."
              tanzu plugin clean || {
                echo "Failed to clean the Tanzu CLI plugins"
              }
              tanzu init || {
                echo "Failed to initialise the Tanzu CLI. Please check network connectivbity and try again."
              }
              break
            ;;
            [Nn]* )
              echo "Skipping Tanzu CLI initialisation"
              break
            ;;
            * )
              echo "Please answer yes or no"
            ;;
          esac
        done
      fi
      figlet "VSCode"
      EOF

      # Set permissions on required directories
      mkdir --parents --mode 0777 /tmp || exit 1
      mkdir --parents --mode 0777 /workdir || exit 1
      mkdir --parents --mode 0777 /workspaces || exit 1
      mkdir --parents --mode 0777 /vscode || exit 1
      mkdir --parents --mode 0777 /var/devcontainer || exit 1
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
    '';

    config = {
      User = containerUser;
      Labels = {
        "org.opencontainers.image.description" = "tanzu";
      };
      Entrypoint = [
      ];
      Cmd = [
        "${pkgs.bashInteractive}/bin/bash"
      ];
      ExposedPorts = {
      };
      Env = [
        "CHARSET=UTF-8"
        "DOCKER_CONFIG=/home/${containerUser}/.docker"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LD_LIBRARY_PATH=/lib;/lib/stdenv;/lib/glibc;/lib64;/lib64/stdenv;/lib64/glibc"
        "PAGER=less"
        "NIX_PAGER=less"
        "PATH=/workdir:/usr/bin:/bin:/sbin"
        "SHELL=${pkgs.bashInteractive}/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm"
        "TZ=UTC"
        "WORKDIR=/workdir"
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/vscode" = {};
      };
    };
  }

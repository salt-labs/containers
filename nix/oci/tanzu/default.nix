{
  pkgs,
  crossPkgs,
  ...
}: let
  #containerUser = "tanzu";
  containerUser = "root";

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
    fakeNss
    #shadowSetup
  ];

  baseImage = pkgs.dockerTools.buildImageWithNixDb {
    name = "docker.io/debian";
    tag = "stable-slim";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = [
        "/bin"
        "/etc"
        "/home"
        "/lib"
        "/lib64"
        "/root"
        "/sbin"
        "/usr"
        "/usr/bin"
        "/usr/lib"
        "/var"
      ];
      paths = with pkgs; [
        bashInteractive
        coreutils-full
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
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu";
    tag = "latest";
    #created = "now";

    #fromImage = baseImage;
    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/bin"
        "/etc"
        "/home"
        "/lib"
        "/lib64"
        "/root"
        "/tmp"
        "/usr"
        "/workdir"
        "/workspaces"
        "/tmp"
      ];

      paths = with pkgs;
        [
          bashInteractive
          bash-completion
          coreutils-full
          which
          cacert

          # VSCode
          iproute
          glibc
          getent
          findutils
          gcc-unwrapped
          nodejs
        ]
        ++ environmentHelpers;
    };

    # Enable fakeRootCommands in fakechroot
    enableFakechroot = true;

    # Run these commands in fakechroot
    fakeRootCommands = ''
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

      # Set permissions
      chmod --verbose --recursive 1777 /tmp || exit 1
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
      # Allow ubuntu ELF binaries to run. VSCode copies it's own into the container.
      chmod +w lib64
      ln -s ${pkgs.glibc}/lib64/ld-linux-x86-64.so.2 lib64/ld-linux-x86-64.so.2
      ln -s ${pkgs.gcc-unwrapped.lib}/lib64/libstdc++.so.6 lib64/libstdc++.so.6
      chmod -w lib64
    '';

    /*

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/bin"
        "/etc"
        "/github"
        "/home"
        "/lib"
        "/lib64"
        "/root"
        "/run"
        "/sbin"
        "/tmp"
        "/usr"
        "/usr/bin"
        "/usr/lib"
        "/var"
        "/workdir"
        "/workspace"
      ];

      paths = with pkgs;
        [
          # Common
          acl
          bash-completion
          bashInteractive
          cacert
          coreutils-full
          curlFull
          findutils
          figlet
          gcc-unwrapped
          getent
          git
          glibc
          gnugrep
          gnused
          gnutar
          gzip
          iproute
          jq
          less
          procps
          ripgrep
          nodejs
          shadow
          starship
          su
          tree
          unzip
          wget
          which
          xz
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
      NAME="SaltOS"
      VERSION_ID="1"
      VERSION="1"
      VERSION_CODENAME="base"
      ID=saltos
      HOME_URL="https://www.saltlabs.tech/"
      SUPPORT_URL="https://www.saltlabs.tech/"
      BUG_REPORT_URL="https://github.com/salt-labs/containers/issues"
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

      chmod --verbose --recursive 0777 /home/${containerUser} || exit 1
      chmod --verbose --recursive 0777 /workdir /workspace || exit 1
      chmod --verbose --recursive 1777 /tmp || exit 1
    '';

    # Run extra commands after the container is created in the final layer.
    extraCommands = ''
      # Symlink bin to usr/bin
      ln -s ../bin usr/bin

      # Allow ubuntu ELF binaries to run. VSCode copies it's own into the container.
      chmod +w lib64
      ln -s ${pkgs.glibc}/lib64/ld-linux-x86-64.so.2 lib64/ld-linux-x86-64.so.2
      ln -s ${pkgs.gcc-unwrapped.lib}/lib64/libstdc++.so.6 lib64/libstdc++.so.6
      chmod -w lib64
    '';

    */

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
        #"DOCKER_CONFIG=/home/${containerUser}/.docker"
        #"HOME=/home/${containerUser}"
        "HOME=/root"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LD_LIBRARY_PATH=${pkgs.gcc-unwrapped.lib}/lib64"
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
    };
  }

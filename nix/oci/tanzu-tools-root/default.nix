{
  pkgs,
  pkgsUnstable,
  crossPkgs,
  crossPkgsUnstable,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  # This container runs as the root user however it's intended
  # to be run from Docker rootless.
  containerUser = "root";
  containerUID = "0";
  containerGID = "0";

  tanzu = pkgs.callPackage ./derivations/tanzu {
    inherit pkgs;
    inherit crossPkgs;
  };

  carvel = pkgs.callPackage ../carvel/carvel.nix {
    inherit pkgs;
    inherit crossPkgs;
  };

  root_files = builtins.path {
    name = "root_files";
    path = ./root/.;
    recursive = true;
  };

  environmentHelpers = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
    #fakeNss
    shadowSetup
  ];

  stablePkgs = with pkgs; [
    # Coreutils
    #busybox
    coreutils-full
    #toybox
    #uutils-coreutils

    # Common
    bash-completion
    bashInteractive
    bat
    bottom
    bind
    bindfs
    cacert
    curlFull
    dialog
    diffutils
    figlet
    fortune
    file
    fuse3
    gawk
    git
    gnugrep
    gnupg
    gnused
    gnutar
    gzip
    hey
    htop
    iputils
    jq
    kmod
    less
    ncurses
    nettools
    openssh
    openssl
    procps
    ripgrep
    rsync
    shellcheck
    starship
    tini
    tree
    unzip
    vim
    wget
    which
    xz
    yq-go

    # User tools
    shadow
    getent
    libcap

    # Nix
    direnv
    nil

    # VSCode
    findutils
    iproute

    # Docker Tools
    dive
    #docker
    #docker-client
    docker-buildx
    docker-gc
    docker-ls
    docker-slim
    docker-proxy
    runc

    # Kubernetes Tools
    clusterctl
    k9s
    kail
    kapp
    #kind
    krew
    kube-bench
    kube-linter
    kubectl
    kubernetes-helm
    kubie
    kustomize
    kustomize-sops
    sops

    # TKG Tools
    pinniped
    sonobuoy
    velero

    # Custom derivations
    carvel
    tanzu
  ];

  unstablePkgs = with pkgsUnstable; [
    # TODO: Check when docker-client is up to v24+
    docker_24
    kind
    glibc
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu-tools-root";
    tag = "latest";
    created = creationDate;

    architecture = "amd64";

    maxLayers = 125;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/"
        "/bin"
        "/etc"
        "/etc/default"
        "/etc/skel"
        "/etc/sudoers.d"
        "/etc/pam.d"
        "/home"
        "/lib"
        "/lib64"
        "/nix"
        "/run"
        "/share"
        "/sbin"
        "/usr"
        "/usr/lib"
        "/usr/lib64"
        "/usr/lib/security"
        "/usr/local"
        "/usr/local/bin"
        "/usr/share/"
        "/usr/share/bash-completion"
        "/var"
        "/var/run"
        "/var/lib"
        "/var/lib/docker"
      ];

      paths =
        stablePkgs
        ++ unstablePkgs
        ++ environmentHelpers
        ++ [root_files];
    };

    # Enable fakeRootCommands in a fake chroot environment.
    enableFakechroot = true;

    # Run these commands in the fake chroot environment.
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      # Setup shadow and pam for root
      ${pkgs.dockerTools.shadowSetup}

      # Make sure shadow bins are in the PATH
      PATH=${pkgs.shadow}/bin/:$PATH

      # Add required groups
      groupadd docker \
        --gid 998 || {
        echo "Failed to add group docker"
        exit 1
      }

      # VSCode includes a bundled nodejs binary which is
      # dynamically linked and hardcoded to look in /lib
      mkdir --parents /lib || {
        echo "Failed to create /lib"
        exit 1
      }
      ln -s ${pkgs.stdenv.cc.cc.lib}/lib /lib/stdenv || {
        echo "Failed to create /lib/stdenv symlink"
        exit 1
      }
      ln -s ${pkgs.glibc}/lib /lib/glibc || {
        echo "Failed to create /lib/glibc symlink"
        exit 1
      }
      mkdir --parents /lib64 || {
        echo "Failed to create /lib64"
        exit 1
      }
      ln -s ${pkgs.stdenv.cc.cc.lib}/lib /lib64/stdenv || {
        echo "Failed to create /lib/stdenv symlink"
        exit 1
      }
      ln -s ${pkgs.glibc}/lib /lib64/glibc || {
        echo "Failed to create /lib64/glibc symlink"
        exit 1
      }
      ln -s /lib64/glibc/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 || {
        echo "Failed to create /lib64/ld-linux-x86-64.so.2 symlink"
        exit 1
      }

      # Systems with sssd will have user and group ids > 65535
      # For those systems you need libnss loaded.
      ln -s ${pkgs.sssd}/lib /lib/lib-sssd  || {
        echo "Failed to create /lib/lib-sssd symlink"
        exit 1
      }

      # Setup root user profile
      cp --recursive --dereference /etc/skel /root
      chown -R root:root /root || {
        echo "Failed to chown /root"
        exit 1
      }
      chmod -R 0751 /root || {
        echo "Failed to chmod /root"
        exit 1
      }

      echo "Setting permissions permissions on required directories"
      mkdir --parents --mode 1777 /run || exit 1
      mkdir --parents --mode 1777 /tmp || exit 1
      mkdir --parents --mode 1777 /usr/lib/ytt || exit 1
      mkdir --parents --mode 1777 /var/devcontainer || exit 1
      mkdir --parents --mode 1777 /vscode || exit 1
      mkdir --parents --mode 1777 /workdir || exit 1
      mkdir --parents --mode 1777 /workspaces || exit 1

      # Update user add defaults
      cat << EOF > /etc/default/useradd
      SHELL=/bin/bash
      HOME=/home
      SKEL=/etc/skel
      CREATE_MAIL_SPOOL=no
      EOF
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
    '';

    config = {
      User = "root";
      Labels = {
        "org.opencontainers.image.description" = "tanzu";
      };
      Entrypoint = [
        "tini"
        "-g"
        "--"
      ];
      Cmd = [
        "/usr/local/bin/entrypoint.sh"
      ];
      ExposedPorts = {
        # DinD
        #"2375/tcp" = {};
        #"2376/tcp" = {};
      };
      Env = [
        "CHARSET=UTF-8"
        "ENABLE_DEBUG=FALSE"
        "ENVIRONMENT_VSCODE=none"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LOG_DESTINATION=file"
        "LOG_FILE=/tmp/tanzu-tools.log"
        "NIX_PAGER=less"
        "PAGER=less"
        "SHELL=${pkgs.bashInteractive}/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm"
        "TZ=UTC"
        "WORKDIR=/workdir"
        #"LD_LIBRARY_PATH=/lib;/lib/stdenv;/lib/glibc;/lib/lib-sssd;/lib64;/lib64/stdenv;/lib64/glibc"
        "LOG_LEVEL=INFO"
        "TANZU_TOOLS_ENABLE_PROXY_SCRIPT=FALSE"
        "TANZU_TOOLS_ENABLE_STARSHIP=FALSE"
        "TANZU_TOOLS_DIALOG_THEME=default"
        "TANZU_TOOLS_SYNC_YTT_LIB=FALSE"
        "TANZU_TOOLS_SYNC_VENDOR=FALSE"
        "TANZU_TOOLS_CLI_PLUGIN_INVENTORY_TAG=latest"
        "TANZU_TOOLS_CLI_PLUGIN_GROUP_TKG_TAG=latest"
        "TANZU_TOOLS_SITES_ENABLED=FALSE"
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/home/${containerUser}" = {};
        "/tmp" = {};
        "/usr/lib/ytt" = {};
        "/var/lib/docker" = {};
        "/vscode" = {};
      };
    };
  }

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

  # A non-root user to add to the container image.
  containerUser = "tanzu";
  containerUID = "1001";
  containerGID = "1001";

  tanzu = pkgs.callPackage ./tanzu.nix {
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
    #shadowSetup
  ];

  stablePkgs = with pkgs; [
    # Common
    bash-completion
    bashInteractive
    bat
    bottom
    bind
    bindfs
    cacert
    coreutils-full
    curlFull
    diffutils
    figlet
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
    procps
    ripgrep
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

    # Nix
    direnv
    nil

    # VSCode
    findutils
    iproute

    # Docker Tools
    #containerd
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
    kail
    kapp
    #kind
    krew
    kube-bench
    kube-linter
    kubectl
    kubernetes-helm
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

    # Custom derivations
    carvel
    tanzu
  ];

  unstablePkgs = with pkgsUnstable; [
    # TODO: Check when docker-client is up to v24+
    docker_24
    kind
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu";
    tag = "latest";
    created = creationDate;

    architecture = "amd64";

    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        #"/bin"
        #"/etc/docker"
        #"/etc/skel"
        #"/usr/local/bin"
        #"/usr/local/share/applications/tanzu-cli"
        #
        "/"
        "/bin"
        "/etc"
        "/etc/skel"
        "/etc/sudoers.d"
        "/etc/pam.d"
        "/home"
        "/lib"
        "/lib64"
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
      groupadd tanzu \
        --gid ${containerGID} || {
        echo "Failed to add group tanzu"
        exit 1
      }
      groupadd docker \
        --gid 998 || {
        echo "Failed to add group docker"
        exit 1
      }

      # Add the container user
      # -M = --no-create-home
      useradd \
        --uid ${containerUID} \
        --comment "Tanzu CLI" \
        --home /home/${containerUser} \
        --shell ${pkgs.bashInteractive}/bin/bash \
        --groups tanzu,docker \
        --no-user-group \
        -M \
        ${containerUser} || {
          echo "Failed to add user ${containerUser}"
          exit 1
        }

      # Update user primary group (manual)
      sed \
        --in-place \
        --regexp-extended \
        --expression "s/^${containerUser}:x:${containerUID}:1000:/${containerUser}:x:${containerUID}:${containerGID}:/" \
        /etc/passwd || {
          echo "Failed to update user ${containerUser} primary group"
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

      # Setup root user profile
      cp --recursive --dereference /etc/skel /root
      chown --recursive root:root /root || {
        echo "Failed to chown /root"
        exit 1
      }
      chmod --recursive 0751 /root || {
        echo "Failed to chmod /root"
        exit 1
      }

      # Setup the container user profile
      cp --recursive --dereference /etc/skel /home/${containerUser} || {
        echo "Failed to copy home template for user ${containerUser}"
        exit 1
      }
      # Fix the home permissions for user ${containerUser}
      chown --recursive ${containerUID}:${containerGID} /home/${containerUser} || {
        echo "Failed to chown home for user ${containerUser}"
        exit 1
      }
      chmod --recursive 0751 /home/${containerUser} || {
        echo "Failed to chmod home for user ${containerUser}"
        exit 1
      }

      # Set permissions on required directories
      mkdir --parents --mode 1777 /run || exit 1
      mkdir --parents --mode 1777 /tmp || exit 1
      mkdir --parents --mode 1777 /usr/lib/ytt || exit 1
      mkdir --parents --mode 1777 /var/devcontainer || exit 1
      mkdir --parents --mode 1777 /vscode || exit 1
      mkdir --parents --mode 1777 /workdir || exit 1
      mkdir --parents --mode 1777 /workspaces || exit 1

      # TEST
      chmod +x /usr/local/bin/entrypoint.sh || {
        echo nope
        exit 1
      }
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
        "ENABLE_PROXY_SCRIPT=FALSE"
        "ENABLE_STARSHIP=FALSE"
        "ENVIRONMENT_VSCODE=none"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LD_LIBRARY_PATH=/lib;/lib/stdenv;/lib/glibc;/lib64;/lib64/stdenv;/lib64/glibc"
        "NIX_PAGER=less"
        "PAGER=less"
        "SHELL=${pkgs.bashInteractive}/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TANZU_CLI_PLUGIN_GROUP_TKG_TAG=latest"
        "TANZU_CLI_PLUGIN_SOURCE_TAG=latest"
        "TERM=xterm"
        "TZ=UTC"
        "WORKDIR=/workdir"
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

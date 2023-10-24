##################################################
#
# Reference: https://www.redhat.com/sysadmin/podman-inside-container
#
##################################################
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
  containerUID = "5000";
  containerGID = "5000";

  tanzu = pkgs.callPackage ./tanzu.nix {
    inherit pkgs;
    inherit crossPkgs;
  };

  carvel = pkgs.callPackage ./carvel.nix {
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
  ];

  unstablePkgs = with pkgsUnstable; [];

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
    util-linux
    vim
    wget
    which
    xz
    yq-go

    # User tools
    shadow
    getent
    su

    # Nix
    direnv
    nil

    # VSCode
    findutils
    iproute

    # Container Tools
    dive
    runc
    crun
    podman
    podman-tui
    fuse-overlayfs
    slirp4netns

    # Kubernetes Tools
    clusterctl
    kail
    kapp
    kind
    krew
    kube-bench
    kube-linter
    kubectl
    kubernetes-helm
    kustomize
    kustomize-sops
    pinniped
    sonobuoy
    sops
    velero
    vendir
    ytt

    # Custom derivations
    carvel
    tanzu
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu-podman";
    tag = "latest";
    created = creationDate;

    architecture = "amd64";

    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/"
        "/bin"
        "/etc"
        "/etc/containers"
        "/etc/pam.d"
        "/etc/skel"
        "/etc/sudoers.d"
        "/home"
        "/lib"
        "/lib64"
        "/run"
        "/sbin"
        "/share"
        "/usr"
        "/usr/lib"
        "/usr/lib/security"
        "/usr/lib64"
        "/usr/local"
        "/usr/local/bin"
        "/usr/share/"
        "/usr/share/bash-completion"
        "/var"
        "/var/lib/containers"
        "/var/run"
      ];

      paths =
        stablePkgs
        ++ unstablePkgs
        ++ [root_files]
        ++ environmentHelpers;
    };

    # Enable fakeRootCommands in a fake chroot environment.
    enableFakechroot = true;

    # Run these commands in the fake chroot environment.
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      # Setup shadow and pam for root
      #${pkgs.dockerTools.shadowSetup}

      # Make sure shadow bins are in the PATH
      export PATH=${pkgs.shadow}/bin/:''${PATH}

      # Add required groups
      groupadd tanzu \
        --gid ${containerGID} || {
        echo "Failed to add group tanzu"
        exit 1
      }

      # Add the container user
      # -M = --no-create-home
      useradd \
        --uid ${containerUID} \
        --comment "Tanzu CLI" \
        --home /home/${containerUser} \
        --shell ${pkgs.bashInteractive}/bin/bash \
        --groups tanzu \
        --no-user-group \
        --system \
        --add-subids-for-system \
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
        echo "Failed to copy profile for ${containerUser}"
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
      mkdir --parents --mode 1777 /tmp || exit 1
      mkdir --parents --mode 1777 /workdir || exit 1
      mkdir --parents --mode 1777 /workspaces || exit 1
      mkdir --parents --mode 1777 /vscode || exit 1
      mkdir --parents --mode 1777 /var/devcontainer || exit 1

      # Setup sub IDs and GIDs for rootless Podman
      #echo "Setting up Sub IDs and GIDs"
      #echo ${containerUser}:10000:65535 > /etc/subuid || exit 1
      #echo ${containerUser}:10000:65535 > /etc/subgid || exit 1
      #chmod 0644 /etc/subuid /etc/subgid || exit 1

      # Setup directories for rootless Podman
      mkdir -p /run/containers/storage || exit 1
      mkdir -p /run/user/${containerUID} || exit 1
      chmod 0777 /run/user/${containerUID} || exit 1

      mkdir -p /var/lib/shared/{overlay-images,overlay-layers,vfs-images,vfs-layers}
      touch /var/lib/shared/overlay-images/images.lock || exit 1
      touch /var/lib/shared/overlay-layers/layers.lock || exit 1
      touch /var/lib/shared/vfs-images/images.lock || exit 1
      touch /var/lib/shared/vfs-layers/layers.lock || exit 1
      chmod -R 0777 /var/lib/shared || exit 1

      # Podman needs this working directory.
      mkdir -p /var/tmp
      chmod -R 0777 /var/tmp

      # HACK: We need to run these as non-root users.
      declare BINS=(
        newgidmap
        newuidmap
      )
      for BIN in "''${BINS[@]}";
      do
        rm -f /bin/''${BIN} || {
          echo "Failed to remove symlink to ''${BIN}"
          exit 1
        }
        cp --dereference ${pkgs.shadow}/bin/''${BIN} /bin/''${BIN} || {
          echo "Failed to copy ''${BIN} to /sbin"
          exit 1
        }
        chmod u+s /bin/''${BIN} || {
          echo "Failed to allow ''${BIN} to run as non-root"
          exit 1
        }
      done
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
    '';

    config = {
      User = containerUser;
      # DinD
      # User = root;
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
      };
      Env = [
        "ENABLE_DEBUG=FALSE"
        "ENABLE_STARSHIP=FALSE"
        "ENABLE_PROXY_SCRIPT=FALSE"
        "TANZU_CLI_PLUGIN_SOURCE_TAG=latest"
        "TANZU_CLI_PLUGIN_GROUP_TKG_TAG=latest"
        "CHARSET=UTF-8"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LD_LIBRARY_PATH=/lib;/lib/stdenv;/lib/glibc;/lib64;/lib64/stdenv;/lib64/glibc"
        "PAGER=less"
        "NIX_PAGER=less"
        "SHELL=${pkgs.bashInteractive}/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm"
        "TZ=UTC"
        "WORKDIR=/workdir"
        "ENVIRONMENT_VSCODE=none"
        "_CONTAINERS_USERNS_CONFIGURED="
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/vscode" = {};
        "/tmp" = {};
        "/home/${containerUser}" = {};
        "/var/lib/containers" = {};
      };
    };
  }

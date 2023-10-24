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
    #fakeNss
    #shadowSetup
  ];

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
          ${user}:x:${toString uid}:${toString gid}::/home/${user}:${runtimeShell}
        ''
      )
      (
        writeTextDir "etc/group" ''
          root:x:0:
          sudo:x:27:${user}
          shadow:x:42:${user}
          plugdev:x:46:${user}
          docker:x:998:${user}
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
    doas
    #shadow # breaks sudo
    super
    getent
    su
    sudo

    # Nix
    direnv
    nil

    # VSCode
    findutils
    #gcc-unwrapped
    #glibc
    iproute

    # Docker Tools
    containerd
    dive
    #docker
    #docker-client
    docker-buildx
    docker-gc
    docker-ls
    docker-slim
    docker-proxy
    runc
    crun
    podman
    podman-tui

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

  unstablePkgs = with pkgsUnstable; [
    # TODO: Check when docker-client is up to v24+
    docker_24
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu";
    tag = "latest";
    # created = creationDate;

    architecture = "amd64";

    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/"
        "/bin"
        "/etc"
        "/etc/containers"
        "/etc/docker"
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
        "/var/lib/docker"
        "/var/run"
      ];

      paths =
        stablePkgs
        ++ unstablePkgs
        ++ [root_files]
        ++ environmentHelpers;
      # HACK: Needed mutable users/groups for entrypoint permission workaround.
      #++ nonRootShadowSetup {
      #  user = containerUser;
      #  uid = containerUID;
      #  gid = containerGID;
      #};
    };

    # Enable fakeRootCommands in a fake chroot environment.
    enableFakechroot = true;

    # Run these commands in the fake chroot environment.
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      # Setup shadow and pam for root
      ${pkgs.dockerTools.shadowSetup}

      # HACK: Roll your own shadow so it's not broken by installing pkgs.shadow
      # https://github.com/NixOS/nixpkgs/blob/a5931fa6e38da31f119cf08127c1aa8f178a22af/pkgs/build-support/docker/default.nix#L153-L175
      declare BINS=(
        usermod
        groupmod
      )
      for BIN in "''${BINS[@]}";
      do
        cp --dereference ${pkgs.shadow}/bin/''${BIN} /sbin/''${BIN} || {
          echo "Failed to copy ''${BIN} to /sbin"
          exit 1
        }
      done

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
      groupadd sudo \
        --gid 27 || {
        echo "Failed to add group sudo"
        exit 1
      }

      # Add the container user
      # -M = --no-create-home
      useradd \
        --uid ${containerUID} \
        --comment "Tanzu CLI" \
        --home /home/${containerUser} \
        --shell ${pkgs.bashInteractive}/bin/bash \
        --groups tanzu,docker,sudo \
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
      cp --recursive --dereference /etc/skel /home/${containerUser}
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

      # Make sudo great again...
      chmod +s /sbin/sudo || {
        echo "Failed to add setuid bit to sudo"
        exit 1
      }
      # If /etc/sudoers is a symlink, remove it
      if [ -L /etc/sudoers ]; then
        rm /etc/sudoers || {
          echo "Failed to remove /etc/sudoers symlink"
          exit 1
        }
        # Copy /etc/sudoers from the sudo pkgs
        cp ${pkgs.sudo}/etc/sudoers /etc/sudoers || {
          echo "Failed to copy /etc/sudoers"
          exit 1
        }
      fi

      # Setup sub IDs and GIDs for rootless podman
      usermod \
        --add-subuids 100000-165535 \
        --add-subgids 100000-165535 \
        root

      usermod \
        --add-subuids 165536-231071 \
        --add-subgiods 165536-231071 \
        ${containerUser}

      # Podman allow Fuse overlay for storage
      chmod 644 /etc/containers/containers.conf
      sed -i \
        -e 's|^#mount_program|mount_program|g' \
        -e '/additionalimage.*/a "/var/lib/shared",' \
        -e 's|^mountopt[[:space:]]*=.*$|mountopt = "nodev,fsync=0"|g' \
        /etc/containers/storage.conf
      mkdir -p /var/lib/shared/{overlay-images,overlay-layers,vfs-images,vfs-layers}
      touch /var/lib/shared/overlay-images/images.lock
      touch /var/lib/shared/overlay-layers/layers.lock
      touch /var/lib/shared/vfs-images/images.lock
      touch /var/lib/shared/vfs-layers/layers.lock
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
        # DinD
        #"2375/tcp" = {};
        #"2376/tcp" = {};
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
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/vscode" = {};
        "/tmp" = {};
        "/home/${containerUser}" = {};
        # DinD
        #"/var/lib/docker" = {};
        # Podman
        "/var/lib/containers" = {};
      };
    };
  }

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
  containerUser = "podman";
  containerUID = "1001";
  containerGID = "1001";

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

  stablePkgs = with pkgs; [
    # User tools
    bashInteractive
    cacert
    coreutils-full
    shadow
    tini

    # Container Tools
    buildah
    crun
    conmon
    podman
    podman-tui
    fuse-overlayfs
    skopeo
    slirp4netns
  ];

  unstablePkgs = with pkgsUnstable; [
    #buildah
    #crun
    #conmon
    #podman
    #skopeo
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "podman";
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
        "/home"
        "/run"
        "/sbin"
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

      # Make sure shadow bins are in the current PATH
      export PATH=${pkgs.shadow}/bin/:''${PATH}

      # Add the container user
      useradd \
        --uid ${containerUID} \
        --comment "Podman" \
        --home /home/${containerUser} \
        --shell ${pkgs.bashInteractive}/bin/bash \
        ${containerUser} || {
          echo "Failed to add user ${containerUser}"
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

      # Set permissions on required temp directories
      mkdir --parents --mode 1777 /tmp || exit 1
      mkdir --parents --mode 1777 /var/tmp || exit 1
      mkdir --parents --mode 1777 /workdir || exit 1

      # Setup sub IDs and GIDs for rootless Podman
      echo "Setting up Sub IDs and GIDs for ${containerUser}"
      echo ${containerUser}:100000:65535 >> /etc/subuid || exit 1
      echo ${containerUser}:100000:65535 >> /etc/subgid || exit 1
      chmod 0644 /etc/subuid /etc/subgid || exit 1

      # Setup directories for rootless Podman
      mkdir -p /run/containers/storage || exit 1
      mkdir -p /run/user/${containerUID} || exit 1
      chown -R ${containerUID}:${containerUID} /run/user/${containerUID} || exit 1

      mkdir -p /var/lib/shared/{overlay-images,overlay-layers,vfs-images,vfs-layers}
      touch /var/lib/shared/overlay-images/images.lock || exit 1
      touch /var/lib/shared/overlay-layers/layers.lock || exit 1
      touch /var/lib/shared/vfs-images/images.lock || exit 1
      touch /var/lib/shared/vfs-layers/layers.lock || exit 1
      chmod -R 0777 /var/lib/shared || exit 1

      # HACK: We need to run these bins as non-root users.
      declare BINS=(
        newgidmap
        newuidmap
      )
      for BIN in "''${BINS[@]}";
      do
        rm -f /bin/''${BIN} /sbin/''${BIN} || {
          echo "Failed to remove symlinks to ''${BIN}"
          exit 1
        }
        cp --dereference ${pkgs.shadow}/bin/''${BIN} /bin/''${BIN} || {
          echo "Failed to copy ''${BIN} to /bin"
          exit 1
        }
        cp --dereference ${pkgs.shadow}/bin/''${BIN} /sbin/''${BIN} || {
          echo "Failed to copy ''${BIN} to /sbin"
          exit 1
        }
        chmod 4755 /bin/''${BIN} || {
          echo "Failed to allow bin ''${BIN} to run as non-root"
          exit 1
        }
        chmod 4755 /sbin/''${BIN} || {
          echo "Failed to allow sbin ''${BIN} to run as non-root"
          exit 1
        }
      done
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
    '';

    config = {
      User = containerUser;
      Labels = {
        "org.opencontainers.image.description" = "podman";
      };
      Entrypoint = [
        "tini"
        "-g"
        "--"
      ];
      Cmd = [
        "${pkgs.bashInteractive}/bin/bash"
      ];
      ExposedPorts = {
      };
      Env = [
        "CHARSET=UTF-8"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
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
        "/tmp" = {};
        "/home/${containerUser}" = {};
        "/var/lib/containers" = {};
      };
    };
  }

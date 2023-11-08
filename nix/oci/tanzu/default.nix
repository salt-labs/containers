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

  # A non-root user that will be used inside the image.
  containerUser = "tanzu";
  containerUID = "1000";
  containerGID = "1000";

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
    su
    super
    sudo
    libcap

    # UID > 65535
    sssd
    #nsncd

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

      # Create a wrappers dir for SUID binaries
      mkdir --parents --mode 0755 /run/wrappers/bin || {
        echo "Failed to create wrappers directory"
        exit 1
      }
      declare -A BINS_SUID
      BINS_SUID[sudo]=""
      BINS_SUID[ping]="cap_net_raw+ep"
      BINS_SUID[setuid]=""
      BINS_SUID[su]=""
      BINS_SUID[newuidmap]=""
      BINS_SUID[newgidmap]=""

      for BIN in "''${!BINS_SUID[@]}" ;
      do

        BIN_NAME="''${BIN}"
        BIN_CAPS="''${BINS_SUID[''$BIN]}"

        echo "Creating wrapper for ''${BIN}"

        if [[ -f /bin/''${BIN} ]];
        then

          cp --dereference /bin/''${BIN} /run/wrappers/bin/''${BIN} || {
            echo "Failed to copy ''${BIN} from /bin to /run/wrappers/bin/"
            exit -1
          }

        elif [[ -f /sbin/''${BIN} ]];
        then

          cp --dereference /sbin/''${BIN} /run/wrappers/bin/''${BIN} || {
            echo "Failed to copy ''${BIN} from /sbin to /run/wrappers/bin/"
            exit -1
          }

        fi

        chmod 0000 /run/wrappers/bin/''${BIN} || {
          echo "Failed to reset permissions on ''${BIN}"
          exit -1
        }

        chown root:root /run/wrappers/bin/''${BIN} || {
          echo "Failed to reset owner and group on ''${BIN}"
           exit -1
        }

        chmod "u+rx,g+rx,o+rx" /run/wrappers/bin/''${BIN_NAME} || {
          echo "Failed to set permissions on ''${BIN_NAME}"
          exit -1
        }

        chmod "+s" /run/wrappers/bin/''${BIN_NAME} || {
          echo "Failed to set SUID on ''${BIN_NAME}"
          exit -1
        }

        if [[ ! "''${BIN_CAPS:-EMPTY}" == "EMPTY" ]];
        then
          ${pkgs.libcap.out}/bin/setcap "cap_setpcap,''${BIN_CAPS}" /run/wrappers/bin/''${BIN} || {
            echo "Failed to add capabilities ''${BIN_CAPS} to ''${BIN_NAME}"
            echo "cap_setpcap''${BIN_CAPS:+,$BIN_CAPS} /run/wrappers/bin/''${BIN}"
            exit -1
          }
        else
          echo "No additional capabilities being added for ''${BIN}"
        fi

        echo "Finished creating wrapper for ''${BIN}"

      done

      # Setup sudo
      mkdir --parents --mode 0755 /etc/sudoers.d || {
        echo "Failed to create sudoers.d directory"
        exit 1
      }
      echo "${containerUser}    ALL=(ALL)    NOPASSWD:    ALL" >> "/etc/sudoers.d/${containerUser}" || {
        echo "Failed to write to sudoers file"
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
      chown --recursive root:root /root || {
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

      # Update login defaults.
      sed \
        --in-place \
        --regexp-extended \
        --expression "s/^UID_MAX.*$/UID_MAX                 2000000000/" \
        /etc/login.defs || {
          echo "Failed to update UID_MAX"
          exit 1
        }
      sed \
        --in-place \
        --regexp-extended \
        --expression "s/^SUB_UID_MIN.*$/SUB_UID_MIN             3000000000/" \
        /etc/login.defs || {
          echo "Failed to update SUB_UID_MIN"
          exit 1
        }
      sed \
        --in-place \
        --regexp-extended \
        --expression "s/^SUB_UID_MAX.*$/SUB_UID_MAX             4000000000/" \
        /etc/login.defs || {
          echo "Failed to update SUB_UID_MAX"
          exit 1
        }

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
        "ENABLE_PROXY_SCRIPT=FALSE"
        "ENABLE_STARSHIP=FALSE"
        "ENVIRONMENT_VSCODE=none"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LD_LIBRARY_PATH=/lib;/lib/stdenv;/lib/glibc;/lib/lib-sssd;/lib64;/lib64/stdenv;/lib64/glibc"
        "NIX_PAGER=less"
        "PAGER=less"
        "SHELL=${pkgs.bashInteractive}/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TANZU_CLI_PLUGIN_GROUP_TKG_TAG=latest"
        "TANZU_CLI_PLUGIN_SOURCE_TAG=latest"
        "TERM=xterm"
        "TZ=UTC"
        "WORKDIR=/workdir"
        "LOG_FILE=/tmp/environment.log"
        "LOG_LEVEL=INFO"
        "LOG_DESTINATION=all"
        "RUN_AS_ROOT=FALSE"
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

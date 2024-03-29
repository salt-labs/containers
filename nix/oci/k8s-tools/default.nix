{
  pkgs,
  pkgsUnstable,
  crossPkgs,
  crossPkgsUnstable,
  self,
  ...
}: let
  # Get the current date in YYYY-MM-DD
  currentDate = pkgs.lib.readFile "${
    pkgs.runCommand "current-time" {
      env.UNIXTIME = builtins.currentTime;
    } "echo -n `date -d @$UNIXTIME +%Y-%m-%d` > $out"
  }";

  # Use the current date for calver.
  containerVersion = currentDate;

  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;
  #creationDate = "now";

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
    shadowSetup
  ];

  stablePkgs = with pkgs; [
    # Coreutils
    uutils-coreutils-noprefix

    # User tools
    bashInteractive
    #bash-completion
    nix-bash-completions
    complete-alias
    bat
    bind
    bindfs
    bottom
    btop
    cacert
    curlFull
    dbus
    dialog
    diffutils
    figlet
    file
    fuse3
    fzf
    fzf-obc
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
    less
    ncurses
    openssh
    openssl
    pass
    pinentry
    procps
    ripgrep
    rsync
    shellcheck
    starship
    tini
    tree
    unzip
    wget
    which
    xz
    yq-go
    shadow
    getent
    libcap

    # Nix
    direnv
    nil

    # Secrets
    age
    sops
    ssh-to-age
    ssh-to-pgp

    # Vim
    vim-full

    # VSCode
    #glibc
    findutils
    iproute

    # Docker Tools
    dive
    docker-buildx
    docker-client
    docker-credential-helpers
    docker-gc
    docker-ls
    docker-proxy
    docker-slim

    # Kubernetes Tools
    clusterctl
    k9s
    kail
    kapp
    kind
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
    #pinniped
    sonobuoy
    velero

    # Custom derivations
    carvel
    tanzu
  ];

  unstablePkgs = with pkgsUnstable; [
    # Pinniped v0.28 has the --timeout parameter
    pinniped
  ];
in
  #pkgs.dockerTools.buildLayeredImage {
  pkgs.dockerTools.buildImage {
    name = "k8s-tools";
    tag = "latest";
    #created = creationDate;

    architecture = "amd64";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";

      paths =
        stablePkgs
        ++ unstablePkgs
        ++ environmentHelpers
        ++ [root_files];

      pathsToLink = [
        "/bin"
        "/etc"
        "/etc/default"
        "/etc/skel"
        "/home"
        "/lib"
        "/lib64"
        "/run"
        "/share"
        "/sbin"
        "/sys"
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
    };

    # NOTE: This requires /dev/kvm
    runAsRoot = ''
      #!${pkgs.runtimeShell}

      # Setup shadow and pam for root
      ${pkgs.dockerTools.shadowSetup}

      # Make sure shadow bins are in the PATH
      PATH=${pkgs.shadow}/bin/:$PATH

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

      echo "Updating useradd defaults"
      cat << EOF > /etc/default/useradd
      SHELL=/bin/bash
      HOME=/home
      SKEL=/etc/skel
      CREATE_MAIL_SPOOL=no
      EOF

      echo "Linking bash completion profile script"
      ln -s ${pkgs.bash-completion}/etc/profile.d/bash_completion.sh /etc/profile.d/bash_completion.sh || {
        echo "Failed to symlink bash completion profile script."
        exit 1
      }

      echo "Linking bash completions"
      ln -s ${pkgs.bash-completion}/share/bash-completion/completions /usr/share/bash-completion/completions || {
        echo "Failed to symlink bash completions."
        exit 1
      }

      echo "Linking bash completions (uutils)"
      ln -s ${pkgs.uutils-coreutils-noprefix}/share/bash-completion/completions /usr/share/bash-completion/completions-uutils || {
        echo "Failed to symlink bash completions (uutils)."
        exit 1
      }

      echo "Linking bash completions (nix)"
      ln -s ${pkgs.nix-bash-completions}/share/bash-completion/completions /usr/share/bash-completion/completions-nix || {
        echo "Failed to symlink bash completions (nix)."
        exit 1
      }
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
    '';

    config = {
      User = "root";
      Labels = {
        "org.opencontainers.image.description" = "k8s-tools";
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
        # Fixed
        "K8S_TOOLS_VERSION=${containerVersion}"
        # Common
        "CHARSET=UTF-8"
        "ENABLE_DEBUG=FALSE"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "LOG_DESTINATION=file"
        "LOG_FILE=/tmp/k8s-tools.log"
        "NIX_PAGER=less"
        "PAGER=less"
        "SHELL=${pkgs.bashInteractive}/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm-256color"
        "TZ=UTC"
        "WORKDIR=/workdir"
        "FIGLET_FONT=standard"
        #"LD_LIBRARY_PATH=/lib;/lib/stdenv;/lib/glibc;/lib/lib-sssd;/lib64;/lib64/stdenv;/lib64/glibc"
        # Kubernetes Tools
        "LOG_LEVEL=INFO"
        "DEBUG_ENABLED=FALSE"
        "K8S_TOOLS_ENVIRONMENT=container"
        "K8S_TOOLS_DIALOG_THEME=default"
        "K8S_TOOLS_DISTRO=vanilla"
        "K8S_TOOLS_ENABLE_PROXY_SCRIPT=FALSE"
        "K8S_TOOLS_ENABLE_STARSHIP=FALSE"
        "K8S_TOOLS_LAUNCH=TRUE"
        "K8S_TOOLS_NAME=k8s-tools"
        "K8S_TOOLS_TITLE=Kubernetes Tools"
        # Tanzu CLI
        "TANZU_CLI_PLUGIN_INVENTORY_TAG=latest"
        "TANZU_CLI_PLUGIN_GROUP_TKG_TAG=latest"
        "TANZU_CLI_SYMLINK_ENABLED=FALSE"
        "TANZU_CLI_SYNC_PLUGINS=FALSE"
        # Tanzu Hacks
        "TANZU_PINNIPED_ENABLED=FALSE"
        "VENDOR_ENABLED=FALSE"
        # Tanzu Sites
        "TANZU_SITES_ENABLED=FALSE"
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/root" = {};
        "/home/${containerUser}" = {};
        "/tmp" = {};
        "/usr/lib/ytt" = {};
        "/var/lib/docker" = {};
        "/vscode" = {};
      };
    };
  }

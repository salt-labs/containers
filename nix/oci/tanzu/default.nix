{
  pkgs,
  crossPkgs,
  self,
  ...
}: let
  modifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
  creationDate = builtins.substring 0 8 modifiedDate;

  # A non-root user to add to the container image.
  containerUser = "tanzu";
  containerUID = "1000";
  containerGID = "1000";

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
        "/etc/skel"
        "/etc/sudoers.d"
        "/home"
        "/lib"
        "/lib64"
        "/root"
        "/run"
        "/sbin"
        "/usr"
        "/usr/lib"
        "/usr/local"
        "/usr/local/bin"
        "/usr/share/"
        "/usr/share/bash-completion"
        "/var"
        "/var/run"
        "/var/lib/docker"
      ];

      paths = with pkgs;
        [
          # Common
          bash-completion
          bashInteractive
          bat
          bottom
          cacert
          coreutils-full
          curlFull
          diffutils
          figlet
          file
          gawk
          git
          gnugrep
          gnupg
          gnused
          gnutar
          gzip
          hey
          htop
          jq
          less
          ncurses
          openssh
          procps
          ripgrep
          shellcheck
          starship
          su
          super
          tini
          tree
          unzip
          vim
          wget
          which
          xz
          yq-go

          # Nix
          direnv
          nil

          # VSCode
          findutils
          gcc-unwrapped
          glibc
          iproute

          # Docker Tools
          containerd
          dive
          docker
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
          kind
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
        ++ [root_files]
        ++ environmentHelpers
        ++ nonRootShadowSetup {
          user = containerUser;
          uid = containerUID;
          gid = containerGID;
        };
    };

    # Enable fakeRootCommands in a fake chroot environment.
    enableFakechroot = true;

    # Run these commands in the fake chroot environment.
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      # VSCode includes a bundled nodejs binary which is
      # dynamically linked and hardcoded to look in /lib
      ln -s ${pkgs.stdenv.cc.cc.lib}/lib /lib/stdenv
      ln -s ${pkgs.glibc}/lib /lib/glibc
      ln -s ${pkgs.stdenv.cc.cc.lib}/lib64 /lib64/stdenv
      ln -s ${pkgs.glibc}/lib64 /lib64/glibc
      ln -s /lib64/glibc/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2

      # Create the home dir for the non-root container user.
      mkdir --parents /home/${containerUser}

      # Copy dotfiles for the user ${containerUser} and root.
      cp --recursive --dereference /etc/skel/. /home/${containerUser}/
      cp --recursive --dereference /etc/skel/. /root/

      # Fix the home permissions for user ${containerUser}
      chown -R ${containerUID}:${containerGID} /home/${containerUser} || {
        echo "Failed to chown home for user ${containerUser}"
        exit 1
      }
      chmod -R +rw /home/${containerUser} || {
        echo "Failed to add rw permissions to /home/${containerUser}"
        exit 1
      }

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
      };
    };
  }

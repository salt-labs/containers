{
  pkgs,
  crossPkgs,
  ...
}: let
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
    #created = "now";

    architecture = "amd64";

    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";

      pathsToLink = [
        "/"
        "/bin"
        "/etc"
        "/home"
        "/lib"
        "/lib64"
        "/root"
        "/run"
        "/sbin"
        "/usr"
        "/usr/local"
        "/usr/share/"
        "/var"
        "/var/run"
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
          gawk
          git
          gnupg
          gnugrep
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
          sudo
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
        ++ environmentHelpers
        ++ nonRootShadowSetup {
          user = containerUser;
          uid = containerUID;
          gid = containerGID;
        };
    };

    # Enable fakeRootCommands in fakechroot
    enableFakechroot = true;

    # Run these commands in fakechroot
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      # TODO: Make sudo work.
      chmod +s /sbin/sudo /bin/sudo
      echo "tanzu ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

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

      # Create the home dir for the container user.
      mkdir --parents /home/${containerUser}

      # Stop clusterctl from checking for updates.
      mkdir --parents /home/${containerUser}/.cluster-api
      cat << EOF > /home/${containerUser}/.cluster-api/clusterctl.yaml
      ---
      CLUSTERCTL_DISABLE_VERSIONCHECK: "true"
      EOF

      # Setup the .bashrc for the container user.
      cat << 'EOF' > /home/${containerUser}/.bashrc
      #!/usr/bin/env bash

      # Initialise the Tanzu CLI
      if [[ -d "''${HOME}/.config/tanzu/tkg" ]];
      then

        echo "Tanzu CLI is already initialised."

      else

        while true;
        do

          clear
          read -r -p "Initialise the Tanzu CLI? y/n: " CHOICE

          case ''$CHOICE in
            [Yy]* )
              echo "Initialising Tanzu CLI..."
              tanzu plugin clean || {
                echo "Failed to clean the Tanzu CLI plugins"
              }
              tanzu init || {
                echo "Failed to initialise the Tanzu CLI. Please check network connectivity and try running 'tanzu init' again."
              }
              break
            ;;
            [Nn]* )
              echo "Skipping Tanzu CLI initialisation"
              break
            ;;
            * )
              echo "Please answer yes or no."
              sleep 3
            ;;
          esac

        done

      fi

      # Enable bash-completion
      if shopt -q progcomp &>/dev/null;
      then
        BASH_COMPLETION_ENABLED="TRUE"
        . "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
      fi

      # shellcheck disable=SC1090
      source <(/bin/starship init bash --print-full-init)

      # Binaries with bash completions
      declare -r BINS=(
        clusterctl
        helm
        imgpkg
        kapp
        kctrl
        kubectl
        kustomize
        tanzu
        ytt
      )

      if [[ "''${BASH_COMPLETION_ENABLED:-FALSE}" == "TRUE" ]];
      then
        echo "Loading bash completions into current shell..."
        for BIN in "''${BINS[@]}";
        do
          echo "Loading bash completion for ''${BIN}"
          source <(''${BIN} completion bash) || {
            echo "Failed to source bash completion for ''${BIN}, skipping."
          }
        done
      fi

      figlet "Tanzu CLI"

      EOF

      # Fix home permissions
      chown -R ${containerUID}:${containerGID} /home/${containerUser} || {
        echo "Failed to chown home for user ${containerUser}"
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

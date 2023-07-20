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
        "/usr/lib"
        "/usr/local"
        "/usr/local/bin"
        "/usr/share/"
        "/usr/share/bash-completion"
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
          direnv
          figlet
          file
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
          tini
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
        ++ [root_files]
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
      chown root:root /sbin/sudo /bin/sudo
      echo "tanzu ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/tanzu

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

      # Create a default global profile.
      cat << 'EOF' > /etc/profile
      #!/usr/bin/env bash

      if [[ "$(id -u)" -eq 0 ]];
      then
        PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
      else
        PATH="/usr/local/bin:/usr/bin:/bin"
      fi
      export PATH

      if [[ -d "/etc/profile.d" ]];
      then
        for FILE in /etc/profile.d/*.sh;
        do
          if [[ -r "''${FILE}" ]];
          then
            . "''${FILE}"
          fi
        done
        unset FILE
      fi
      EOF
      chmod +x /etc/profile

      # Default user .bashrc
      mkdir --parents /etc/skel
      cat << 'EOF' > /etc/skel/.bashrc
      #!/usr/bin/env bash

      if [[ -f "/etc/profile" ]];
      then
        echo "Loading global shell profile..."
        . "/etc/profile"
      fi

      if [[ -n "''${BASH_VERSION}" ]];
      then
        if [[ -f "''${HOME}/.profile" ]];
        then
          echo "Loading user shell profile..."
          . "''${HOME}/.profile"
        fi

        # shellcheck disable=SC1090
        source <(/bin/starship init bash --print-full-init)

      fi
      EOF
      chmod +x /etc/skel/.bashrc

      # Create clusterctl config
      mkdir --parents /etc/skel/.cluster-api
      cat << EOF > /etc/skel/.cluster-api/clusterctl.yaml
      ---
      CLUSTERCTL_DISABLE_VERSIONCHECK: "true"
      EOF

      # Setup the Tanzu profile for all users.
      cat << 'EOF' > /etc/profile.d/tanzu.sh
      #!/usr/bin/env bash

      set -m

      # Variables
      export YTT_LIB="/usr/lib/ytt/"

      # HACK: A better method is needed.
      # Check for a proxy settings script.
      if [[ "''${ENABLE_PROXY_SCRIPT:-FALSE}" == "TRUE" ]];
      then
        if [[ -f "''${WORKDIR}/scripts/proxy.sh" ]];
        then
          echo "Loading proxy settings from ''${WORKDIR}/scripts/proxy.sh"
          source "''${WORKDIR}/scripts/proxy.sh" && proxy_on || {
            echo "Failed to enable proxy settings"
            exit 1
          }
        else
          echo "Proxy settings are enabled but ''${WORKDIR}/scripts/proxy.sh does not exist. Have you mounted the bind volume?"
          exit 1
        fi
      else
        echo "The Proxy script is not enabled, assuming direct internet access."
      fi

      # We need more than one check due to bind mounts.
      # The rules that define whether the CLI has been "initialized" are:
      if [[ -f "''${HOME}/.config/tanzu/config.yaml" ]];
      then
        if [[ -d "''${HOME}/.config/tanzu/tkg" ]];
        then
          if [[ -f "''${HOME}/.config/tanzu/tkg/config.yaml" ]];
          then
            TANZU_CLI_INIT_DONE="TRUE"
          fi
        fi
      fi

      # Initialise the Tanzu CLI
      if [[ "''${TANZU_CLI_INIT_DONE:-FALSE}" == "TRUE" ]];
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

              # HACK: A better method is needed, perhaps interactive 'tanzu plugin source'
              if [[ "''${TANZU_PULL_THROUGH_CACHE:-EMPTY}" == "EMPTY" ]];
              then

                echo "No pull-through prefix provided, using default."

              else

                echo "Pull-through prefix provided, prefixing ''${TANZU_PULL_THROUGH_CACHE}"

                # Capture existing OCI URL
                TANZU_CLI_OCI_URL="$(cat ''${HOME}/.config/tanzu/config.yaml | yq '.clientOptions.cli.discoverySources.[0].oci.image')"

                # Add the pull-through cache OCI URL
                tanzu plugin source add \
                  --name pull-through-cache \
                  --type oci \
                  --uri "''${TANZU_PULL_THROUGH_CACHE}/''${TANZU_CLI_OCI_URL}" || {
                    echo "Failed to add the pull-through cache Tanzu CLI plugin source"
                  }

              fi

              tanzu init || {
                echo "Failed to initialise the Tanzu CLI using configured sources."
                echo "Please check network connectivity and try running 'tanzu init' again."
              }

              tanzu plugin sync || {
                echo "Failed to synchronise Tanzu CLI plugins"
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

      # Binaries we need to source manual bash completions from.
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
      # TODO: vendir
      # vendir issue: https://github.com/carvel-dev/vendir/issues/275
      # The workaround is fragile.

      if shopt -q progcomp;
      then
        echo "Loading bash completions into current shell..."
        for BIN in "''${BINS[@]}";
        do
          source <(''${BIN} completion bash) || {
            echo "Failed to source bash completion for ''${BIN}, skipping."
          }
        done
      fi

      figlet "Tanzu CLI"

      EOF
      chmod +x /etc/profile.d/tanzu.sh

      # Create a wrapper entrypoint
      cat << 'EOF' > /usr/local/bin/entrypoint.sh
      #! /usr/bin/env bash

      clear

      # Launch an interactive shell session.
      /bin/bash -i

      while true;
      do

        clear

        # If bash exits, ask if we should restart or break and exit.
        echo -e "\n"
        echo "Your current shell session in this container has terminated."
        read -r -p "Start a new shell session? y/n: " CHOICE

        case ''$CHOICE in

          [Yy]* )

            echo "Restarting shell..."

            # Launch an interactive shell session.
            /bin/bash -i

          ;;

          [Nn]* )

            echo "Exiting..."
            break

          ;;

          * )

            echo "Please answer yes or no."
            sleep 3

          ;;

        esac

      done

      clear
      figlet "Goodbye!"
      exit 0
      EOF
      chmod +x "/usr/local/bin/entrypoint.sh"

      # Create the home dir for the container user.
      mkdir --parents /home/${containerUser}

      # Copy dotfiles for user ${containerUser} and root.
      cp --recursive /etc/skel/. /home/${containerUser}/
      cp --recursive /etc/skel/. /root/

      # Fix home permissions for user ${containerUser}
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
        "tini"
        "--"
      ];
      Cmd = [
        "/usr/local/bin/entrypoint.sh"
      ];
      ExposedPorts = {
      };
      Env = [
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
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/vscode" = {};
      };
    };
  }

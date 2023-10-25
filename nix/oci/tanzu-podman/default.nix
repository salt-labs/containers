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
  containerUID = "1000";
  containerGID = "1000";

  baseImage = pkgs.dockerTools.pullImage {
    imageName = "quay.io/podman/stable";
    imageDigest = "sha256:8265953034d4d1b1d559aa02bf46289046d3a2cd2b808ed2a1e1073d78a25ae1";
    sha256 = "sha256-qI0sEyUosXGOS7td4jeLswCG6+7gQrzlFyGAKI4FG+k=";
    finalImageTag = "v4.7.0";
    finalImageName = "podman";
  };

  tanzu = pkgs.callPackage ../tanzu/tanzu.nix {
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
  ];

  stablePkgs = with pkgs; [
    # Common
    bat
    bottom
    figlet
    file
    git
    hey
    htop
    iputils
    jq
    less
    lurk
    nettools
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

    # Nix
    direnv
    nil

    # VSCode
    findutils
    iproute

    # Container Tools
    dive

    # Kubernetes Tools
    clusterctl
    kail
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
    kind
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "tanzu-podman";
    tag = "latest";
    created = creationDate;

    architecture = "amd64";

    fromImage = baseImage;
    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";

      paths =
        stablePkgs
        ++ unstablePkgs
        ++ environmentHelpers
        ++ [root_files];

      pathsToLink = [
        "/bin"
        "/usr/local/bin"
        "/usr/local/share/applications/tanzu-cli"
      ];
    };

    # Enable fakeRootCommands in a fake chroot environment.
    enableFakechroot = true;

    # Run these commands in the fake chroot environment.
    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      mkdir --parents --mode 0755 /home/${containerUser}/.cluster-api
      cat << EOF > /home/${containerUser}/.cluster-api/clusterctl.yaml
      ---
      CLUSTERCTL_DISABLE_VERSIONCHECK: "true"
      EOF

      # Reset user home permissions
      chown -R ${containerUID}:${containerUID} /home/${containerUser}

      mkdir --parents --mode 0755 /etc/systemd/system/user@.service.d
      cat << EOF > /etc/systemd/system/user@.service.d/delegate.conf
      [Service]
      Delegate=yes
      EOF

      mkdir --parents --mode 0755 /etc/modules-load.d/
      cat << EOF > /etc/modules-load.d/iptables.conf
      ip6_tables
      ip6table_nat
      ip_tables
      iptable_nat
      EOF

      # Systemd shennanigans

      rm -f \
        /lib/systemd/system/multi-user.target.wants/* \
        /etc/systemd/system/*.wants/* \
        /lib/systemd/system/local-fs.target.wants/* \
        /lib/systemd/system/sockets.target.wants/*udev* \
        /lib/systemd/system/sockets.target.wants/*initctl* \
        /lib/systemd/system/sysinit.target.wants/systemd-tmpfiles-setup* \
        /lib/systemd/system/systemd-update-utmp*

      cat << EOF > /etc/systemd/system/systemd-in-container.target
      [Unit]
      Description=Target for running systemd inside a container
      Requires=systemd-in-container.service systemd-logind.service systemd-user-sessions.service
      EOF

      env > /etc/systemd/system/systemd-in-container.env

      cat << EOF > /etc/systemd/system/systemd-in-container.service
      [Unit]
      Description=Service for running systemd inside a container

      [Service]
      ExecStart=/bin/bash -exc "source /etc/docker-entrypoint-cmd"
      # EXIT_STATUS is either an exit code integer or a signal name string, see systemd.exec(5)
      ExecStopPost=/bin/bash -ec "if echo \''${EXIT_STATUS} | grep [A-Z] > /dev/null; then echo >&2 \"got signal \''${EXIT_STATUS}\"; systemctl exit \$(( 128 + \$( kill -l \''${EXIT_STATUS} ) )); else systemctl exit \''${EXIT_STATUS}; fi"
      StandardInput=tty-force
      StandardOutput=inherit
      StandardError=inherit
      WorkingDirectory=$(pwd)
      EnvironmentFile=/etc/systemd/system/systemd-in-container.env

      [Install]
      WantedBy=multi-user.target
      EOF

      systemctl mask systemd-firstboot.service systemd-udevd.service systemd-modules-load.service
      systemctl unmask systemd-logind
      systemctl enable systemd-in-container.service

      # Set permissions on volume directories.
      mkdir --parents --mode 1777 /run || exit 1
      mkdir --parents --mode 1777 /tmp || exit 1
      mkdir --parents --mode 1777 /usr/lib/ytt || exit 1
      mkdir --parents --mode 1777 /var/devcontainer || exit 1
      mkdir --parents --mode 1777 /vscode || exit 1
      mkdir --parents --mode 1777 /workdir || exit 1
      mkdir --parents --mode 1777 /workspaces || exit 1
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
        "-w"
        "--"
      ];
      #Entrypoint = [
      #  "/sbin/init"
      #  "--show-status=false"
      #  #"--unit=systemd-in-container.target"
      #];
      Cmd = [
        "/usr/local/bin/entrypoint.sh"
      ];
      ExposedPorts = {
      };
      Env = [
        "CHARSET=UTF-8"
        "ENABLE_DEBUG=FALSE"
        "ENABLE_PROXY_SCRIPT=FALSE"
        "ENABLE_STARSHIP=FALSE"
        "ENVIRONMENT_VSCODE=none"
        "KIND_EXPERIMENTAL_PROVIDER=podman"
        "KIND_EXPERIMENTAL_CONTAINERD_SNAPSHOTTER=fuse-overlayfs"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        "NIX_PAGER=less"
        "PAGER=less"
        "TANZU_CLI_PLUGIN_GROUP_TKG_TAG=latest"
        "TANZU_CLI_PLUGIN_SOURCE_TAG=latest"
        "TERM=xterm"
        "TZ=UTC"
        "WORKDIR=/workdir"
        "_CONTAINERS_USERNS_CONFIGURED="
      ];
      WorkingDir = "/workdir";
      WorkDir = "/workdir";
      Volumes = {
        "/home/${containerUser}" = {};
        "/tmp" = {};
        "/usr/lib/ytt" = {};
        "/var/lib/containers" = {};
        "/vscode" = {};
      };
    };
  }

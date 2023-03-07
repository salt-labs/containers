{pkgs, ...}: let
  containerUser = "ci";

  entrypoint = pkgs.callPackage ./entrypoint {};

  environmentHelpers = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
    #fakeNss
  ];

  baseImage = pkgs.dockerTools.buildImageWithNixDb {
    name = "docker.io/debian";
    tag = "stable-slim";
    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = [
        "/bin"
        "/home"
        "/var"
      ];
      paths = with pkgs; [
        bash
        coreutils
        nix
      ];
    };
    config = {
      Env = [
        "NIX_PAGER=cat"
        "USER=nobody"
      ];
    };
  };

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
          ${user}:x:${toString uid}:${toString gid}::/home/${user}:
        ''
      )
      (
        writeTextDir "etc/group" ''
          root:x:0:
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
    name = "ci";
    tag = "latest";
    created = "now";

    #fromImage = baseImage;
    maxLayers = 100;

    contents = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = [
        "/bin"
        "/etc"
        "/home"
        "/lib"
        "/root"
        "/run"
        "/sbin"
        "/usr"
        "/var"
        "/tmp"
      ];

      paths = with pkgs;
        [
          # Common
          bash
          bash-completion
          cacert
          coreutils-full
          curlFull
          getopt
          git
          jq
          less
          libcap
          ncurses
          readline
          sudo
          shadow
          tree
          tzdata
          unzip
          vim
          wget
          yq

          # Everything including the kitchen sink.
          brakeman
          buildah
          clair
          cosign
          flawfinder
          gitleaks
          gosec
          govc
          grype
          hadolint
          helm
          kics
          kube-linter
          kubectl
          kubesec
          license_finder
          packer
          secretscanner
          shellcheck
          skopeo
          nodePackages.snyk
          tflint
          tfsec
          trivy

          # Entrypoint
          entrypoint
        ]
        ++ environmentHelpers; #++ nonRootShadowSetup { uid = 1000; user = "ci"; };
    };

    enableFakechroot = true;

    fakeRootCommands = ''
      #!${pkgs.runtimeShell}

      ${pkgs.dockerTools.shadowSetup}

      groupadd \
        sudo

      useradd \
        --home-dir /home/${containerUser} \
        --create-home \
        --shell /bin/bash \
        --uid 1000 \
        ${containerUser}

      usermod \
        --append \
        --groups sudo \
        ${containerUser}

      echo \
        '%sudo ALL=(ALL) NOPASSWD:ALL' >> \
        /etc/sudoers.d/${containerUser}

      chown \
        --recursive \
        ${containerUser}:${containerUser} \
        /home/${containerUser}

      mkdir --parents \
        /var/lib/containers \
        /var/tmp \
        /var/tmp/containers/rootless

      chmod --recursive 777 \
        /var/lib/containers \
        /var/tmp \
        /var/tmp/containers/rootless

      mkdir --parents \
        /etc/containers \
        /run/containers/storage \
        /var/lib/containers/storage

      echo "export BUILDAH_ISOLATION=chroot" >> /root/.bashrc

      cat <<- EOF > /etc/containers/storage.conf
      [storage]
      driver = "vfs"
      runroot = "/run/containers/storage"
      graphroot = "/var/lib/containers/storage"
      rootless_storage_path = "/var/tmp/containers/rootless"
      EOF

      cat <<- EOF > /etc/containers/policy.json
      {
        "default": [{"type": "insecureAcceptAnything"}]
      }
      EOF

      touch /etc/subgid /etc/subuid \
        && chmod g=u /etc/subgid /etc/subuid /etc/passwd \
        && echo root:10000:65536 > /etc/subuid \
        && echo root:10000:65536 > /etc/subgid


    '';

    config = {
      Labels = {
        "org.opencontainers.image.description" = "Codestream CI";
      };
      Entrypoint = [
        "${entrypoint}/bin/wrapper"
      ];
      Cmd = [
      ];
      ExposedPorts = {
      };
      Env = [
        "CHARSET=UTF-8"
        "LANG=C.UTF-8"
        "LC_COLLATE=C"
        #"PS1='🐳  \[\033[1;36m\]\h \[\033[1;34m\]\W\[\033[0;35m\] \[\033[1;36m\]# \[\033[0m\]'"
        "SHELL=/bin/bash"
        "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        "TERM=xterm"
        "TZ=UTC"
      ];
      WorkingDir = "/workdir";
    };
  }

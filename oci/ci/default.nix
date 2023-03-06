{pkgs, ...}: let
  entrypoint = pkgs.callPackage ./entrypoint {};
in
  pkgs.dockerTools.buildImage {
    name = "ci";
    tag = "latest";
    created = "now";

    copyToRoot = pkgs.buildEnv {
      name = "image-root";
      pathsToLink = ["/bin"];

      paths = with pkgs; [
        # Common
        bash
        bash-completion
        coreutils-full
        curlFull
        cacert
        getopt
        ncurses
        readline
        tzdata

        # Tools
        git
        jq
        less
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
      ];
    };

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

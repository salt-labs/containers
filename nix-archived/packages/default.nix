{
  self,
  inputs,
  systems,
  nixpkgs,
  ...
}: let
  forEachSystem = nixpkgs.lib.genAttrs (import systems);
  pkgs = system: nixpkgs.legacyPackages.${system};
in
  forEachSystem (system: {
    devenv-up = self.devShells.${system}.default.config.procfileScript;

    brakeman = import ../oci/brakeman {
      inherit self;
      inherit pkgs;
    };

    buildah = import ../oci/buildah {
      inherit self;
      inherit pkgs;
    };

    carvel = import ../oci/carvel {
      inherit self;
      inherit pkgs;
    };

    caddy = import ../oci/caddy {
      inherit self;
      inherit pkgs;
    };

    clair = import ../oci/clair {
      inherit self;
      inherit pkgs;
    };

    cmake = import ../oci/cmake {
      inherit self;
      inherit pkgs;
    };

    #codestream-ci = import ../oci/codestream-ci {
    #inherit self;
    #  inherit pkgs;
    #  #inherit pkgCodestreamCLI;
    #};

    codeql = import ../oci/codeql {
      inherit self;
      inherit pkgs;
    };

    cosign = import ../oci/cosign {
      inherit self;
      inherit pkgs;
    };

    flawfinder = import ../oci/flawfinder {
      inherit self;
      inherit pkgs;
    };

    gitleaks = import ../oci/gitleaks {
      inherit self;
      inherit pkgs;
    };

    gnumake = import ../oci/gnumake {
      inherit self;
      inherit pkgs;
    };

    gosec = import ../oci/gosec {
      inherit self;
      inherit pkgs;
    };

    govc = import ../oci/govc {
      inherit self;
      inherit pkgs;
    };

    grype = import ../oci/grype {
      inherit self;
      inherit pkgs;
    };

    hadolint = import ../oci/hadolint {
      inherit self;
      inherit pkgs;
    };

    hello = import ../oci/hello {
      inherit self;
      inherit pkgs;
    };

    helm = import ../oci/helm {
      inherit self;
      inherit pkgs;
    };

    hugo = import ../oci/hugo {
      inherit self;
      inherit pkgs;
    };

    # TODO: fix
    #idem = import ../oci/idem {
    #  inherit self;
    #  inherit nixpkgs;
    #  inherit pkgs;
    #  inherit system;
    #  inherit poetry2nix;
    #};

    kaniko = import ../oci/kaniko {
      inherit self;
      inherit pkgs;
    };

    kics = import ../oci/kics {
      inherit self;
      inherit pkgs;
    };

    kpack = import ../oci/kpack {
      inherit self;
      inherit pkgs;
    };

    kube-linter = import ../oci/kube-linter {
      inherit self;
      inherit pkgs;
    };

    kubectl = import ../oci/kubectl {
      inherit self;
      inherit pkgs;
    };

    kubesec = import ../oci/kubesec {
      inherit self;
      inherit pkgs;
    };

    license_finder = import ../oci/license_finder {
      inherit self;
      inherit pkgs;
    };

    #loopy = import ../oci/loopy {
    #  inherit self;
    #  inherit pkgs;
    #  inherit pkgLoopy;
    #};

    packer = import ../oci/packer {
      inherit self;
      inherit pkgs;
    };

    #podman = import ../oci/podman {
    #  inherit self;
    #  inherit pkgs;
    #};

    pivnet = import ../oci/pivnet {
      inherit self;
      inherit pkgs;
    };

    salt = import ../oci/salt {
      inherit self;
      inherit pkgs;
    };

    secretscanner = import ../oci/secretscanner {
      inherit self;
      inherit pkgs;
    };

    semgrep = import ../oci/semgrep {
      inherit self;
      inherit pkgs;
    };

    skopeo = import ../oci/skopeo {
      inherit self;
      inherit pkgs;
    };

    snyk = import ../oci/snyk {
      inherit self;
      inherit pkgs;
    };

    syft = import ../oci/syft {
      inherit self;
      inherit pkgs;
    };

    k8s-tools = import ../oci/k8s-tools {
      inherit self;
      inherit pkgs;
    };

    terraform = import ../oci/terraform {
      inherit self;
      inherit pkgs;
    };

    terraform-ls = import ../oci/terraform-ls {
      inherit self;
      inherit pkgs;
    };

    tflint = import ../oci/tflint {
      inherit self;
      inherit pkgs;
    };

    tfsec = import ../oci/tfsec {
      inherit self;
      inherit pkgs;
    };

    trivy = import ../oci/trivy {
      inherit self;
      inherit pkgs;
    };
  })

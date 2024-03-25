##################################################
# Notes:
#
#   # Build & run container
#   nix build --impure ".#packages.\"${BUILD_SYSTEM}.${HOST_SYSTEM}\".${CONTAINER}"
#   docker load < result
#   docker run -it --rm ${CONTAINER}:latest
#   Examples: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix
#
#   # Use devShell
#   nix develop
#
#   # Pre-fetch into cache
#   nix build <PACKAGE_HERE> --json | jq '.[0].outputs.out' | cachix push salt-labs
#
##################################################
{
  description = "Containers";

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "cachix";
      repo = "devenv-nixpkgs";
      ref = "rolling";
      flake = true;
    };

    systems = {
      type = "github";
      owner = "nix-systems";
      repo = "default";
      ref = "main";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      type = "github";
      owner = "cachix";
      repo = "pre-commit-hooks.nix";
      ref = "master";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv = {
      type = "github";
      owner = "cachix";
      repo = "devenv";
      ref = "main";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-generators = {
      type = "github";
      owner = "nix-community";
      repo = "nixos-generators";
      ref = "master";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      type = "github";
      owner = "nix-community";
      repo = "fenix";
      ref = "main";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    poetry2nix = {
      type = "github";
      owner = "nix-community";
      repo = "poetry2nix";
      ref = "master";
      flake = true;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #codestream-cli = {
    #  type = "github";
    #  owner = "salt-labs";
    #  repo = "codestream-cli";
    #  ref = "trunk";
    #  flake = true;
    #};

    loopy = {
      type = "github";
      owner = "salt-labs";
      repo = "loopy";
      ref = "trunk";
      flake = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    devenv,
    poetry2nix,
    #codestream-cli,
    loopy,
    ...
  } @ inputs: let
    inherit (self) outputs;

    forEachSystem = nixpkgs.lib.genAttrs (import systems);

    pkgsImport = system: nixpkgs.legacyPackages.${system};
  in {
    ###############
    # Packages
    ###############

    packages = forEachSystem (system: let
      pkgs = pkgsImport system;

      # codestream-cli
      #pkgCodestreamCLI = codestream-cli.packages.${system}.codestream-cli;

      # Loopy
      pkgLoopy = loopy.packages.${system}.loopy;

      devenv-up = self.devShells.${system}.default.config.procfileScript;
    in {
      brakeman = import ./nix/oci/brakeman {
        inherit self;
        inherit pkgs;
      };

      buildah = import ./nix/oci/buildah {
        inherit self;
        inherit pkgs;
      };

      carvel = import ./nix/oci/carvel {
        inherit self;
        inherit pkgs;
      };

      caddy = import ./nix/oci/caddy {
        inherit self;
        inherit pkgs;
      };

      clair = import ./nix/oci/clair {
        inherit self;
        inherit pkgs;
      };

      cmake = import ./nix/oci/cmake {
        inherit self;
        inherit pkgs;
      };

      #codestream-ci = import ./nix/oci/codestream-ci {
      #inherit self;
      #  inherit pkgs;
      #  #inherit pkgCodestreamCLI;
      #};

      codeql = import ./nix/oci/codeql {
        inherit self;
        inherit pkgs;
      };

      cosign = import ./nix/oci/cosign {
        inherit self;
        inherit pkgs;
      };

      flawfinder = import ./nix/oci/flawfinder {
        inherit self;
        inherit pkgs;
      };

      gitleaks = import ./nix/oci/gitleaks {
        inherit self;
        inherit pkgs;
      };

      gnumake = import ./nix/oci/gnumake {
        inherit self;
        inherit pkgs;
      };

      gosec = import ./nix/oci/gosec {
        inherit self;
        inherit pkgs;
      };

      govc = import ./nix/oci/govc {
        inherit self;
        inherit pkgs;
      };

      grype = import ./nix/oci/grype {
        inherit self;
        inherit pkgs;
      };

      hadolint = import ./nix/oci/hadolint {
        inherit self;
        inherit pkgs;
      };

      hello = import ./nix/oci/hello {
        inherit self;
        inherit pkgs;
      };

      helm = import ./nix/oci/helm {
        inherit self;
        inherit pkgs;
      };

      hugo = import ./nix/oci/hugo {
        inherit self;
        inherit pkgs;
      };

      # TODO: fix
      #idem = import ./nix/oci/idem {
      #  inherit self;
      #  inherit nixpkgs;
      #  inherit pkgs;
      #  inherit system;
      #  inherit poetry2nix;
      #};

      kaniko = import ./nix/oci/kaniko {
        inherit self;
        inherit pkgs;
      };

      kics = import ./nix/oci/kics {
        inherit self;
        inherit pkgs;
      };

      kpack = import ./nix/oci/kpack {
        inherit self;
        inherit pkgs;
      };

      kube-linter = import ./nix/oci/kube-linter {
        inherit self;
        inherit pkgs;
      };

      kubectl = import ./nix/oci/kubectl {
        inherit self;
        inherit pkgs;
      };

      kubesec = import ./nix/oci/kubesec {
        inherit self;
        inherit pkgs;
      };

      license_finder = import ./nix/oci/license_finder {
        inherit self;
        inherit pkgs;
      };

      #loopy = import ./nix/oci/loopy {
      #  inherit self;
      #  inherit pkgs;
      #  inherit pkgLoopy;
      #};

      packer = import ./nix/oci/packer {
        inherit self;
        inherit pkgs;
      };

      #podman = import ./nix/oci/podman {
      #  inherit self;
      #  inherit pkgs;
      #};

      pivnet = import ./nix/oci/pivnet {
        inherit self;
        inherit pkgs;
      };

      salt = import ./nix/oci/salt {
        inherit self;
        inherit pkgs;
      };

      secretscanner = import ./nix/oci/secretscanner {
        inherit self;
        inherit pkgs;
      };

      semgrep = import ./nix/oci/semgrep {
        inherit self;
        inherit pkgs;
      };

      skopeo = import ./nix/oci/skopeo {
        inherit self;
        inherit pkgs;
      };

      snyk = import ./nix/oci/snyk {
        inherit self;
        inherit pkgs;
      };

      syft = import ./nix/oci/syft {
        inherit self;
        inherit pkgs;
      };

      k8s-tools = import ./nix/oci/k8s-tools {
        inherit self;
        inherit pkgs;
      };

      terraform = import ./nix/oci/terraform {
        inherit self;
        inherit pkgs;
      };

      terraform-ls = import ./nix/oci/terraform-ls {
        inherit self;
        inherit pkgs;
      };

      tflint = import ./nix/oci/tflint {
        inherit self;
        inherit pkgs;
      };

      tfsec = import ./nix/oci/tfsec {
        inherit self;
        inherit pkgs;
      };

      trivy = import ./nix/oci/trivy {
        inherit self;
        inherit pkgs;
      };
    });

    ###############
    # DevShells
    ###############

    devShells = forEachSystem (system: let
      pkgs = pkgsImport system;
    in {
      devenv = import ./nix/devshells/devenv {
        inherit inputs;
        inherit system;
        inherit pkgs;
        inherit nixpkgs;
      };

      default = self.devShells.${system}.devenv;
    });
  };
}

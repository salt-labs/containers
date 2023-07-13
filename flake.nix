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
#   nix build X --json | jq '.[0].outputs.out' | cachix push salt-labs
#
##################################################
{
  description = "Containers";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-23.05";
      flake = true;
    };

    nixpkgs-unstable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
      flake = true;
    };

    pre-commit-hooks = {
      type = "github";
      owner = "cachix";
      repo = "pre-commit-hooks.nix";
      ref = "master";
      flake = true;
    };

    devenv = {
      type = "github";
      owner = "cachix";
      repo = "devenv";
      ref = "main";
      flake = true;
    };

    fenix = {
      type = "github";
      owner = "nix-community";
      repo = "fenix";
      ref = "main";
      flake = true;
    };

    poetry2nix = {
      type = "github";
      owner = "nix-community";
      repo = "poetry2nix";
      ref = "master";
      flake = true;
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
    nixpkgs-unstable,
    devenv,
    poetry2nix,
    #codestream-cli,
    loopy,
    ...
  } @ inputs: let
    inherit (self) outputs;

    supportedSystems = [
      #"aarch64-darwin"
      #"aarch64-linux"
      #"x86_64-darwin"
      "x86_64-linux"
    ];

    forAllSystems = f:
      builtins.listToAttrs (map (buildPlatform: {
          name = buildPlatform;
          value = builtins.listToAttrs (map (hostPlatform: {
              name = hostPlatform;
              value = f buildPlatform hostPlatform;
            })
            supportedSystems);
        })
        supportedSystems);

    pkgsImportCrossSystem = buildPlatform: hostPlatform:
      import nixpkgs {
        system = buildPlatform;
        overlays = [];
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
        crossSystem =
          if buildPlatform == hostPlatform
          then null
          else {
            config = hostPlatform;
          };
      };

    pkgsImportCrossSystemUnstable = buildPlatform: hostPlatform:
      import nixpkgs-unstable {
        system = buildPlatform;
        overlays = [];
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
        crossSystem =
          if buildPlatform == hostPlatform
          then null
          else {
            config = hostPlatform;
          };
      };

    flattenPackages = systems:
      builtins.foldl' (acc: system:
        builtins.foldl' (
          innerAcc: hostPlatform:
            innerAcc // {"${system}.${hostPlatform}" = systems.${system}.${hostPlatform};}
        )
        acc (builtins.attrNames systems.${system})) {} (builtins.attrNames systems);

    pkgsAllowUnfree = {
      nixpkgs = {
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
    };
  in {
    ###############
    # Packages
    ###############
    packages = flattenPackages (forAllSystems (buildPlatform: hostPlatform: let
      # Build Platform
      system = buildPlatform;
      pkgs = pkgsImportCrossSystem buildPlatform buildPlatform;
      pkgsUnstable = pkgsImportCrossSystemUnstable buildPlatform buildPlatform;

      # Host Platform
      crossPkgs = pkgsImportCrossSystem buildPlatform hostPlatform;
      crossPkgsUnstable = pkgsImportCrossSystemUnstable buildPlatform hostPlatform;

      # codestream-cli
      #pkgCodestreamCLI = codestream-cli.packages.${hostPlatform}.codestream-cli;

      # Loopy
      pkgLoopy = loopy.packages.${hostPlatform}.loopy;
    in {
      brakeman = import ./nix/oci/brakeman {
        inherit pkgs;
        inherit crossPkgs;
      };

      buildah = import ./nix/oci/buildah {
        inherit pkgs;
        inherit crossPkgs;
      };

      carvel = import ./nix/oci/carvel {
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
      };

      caddy = import ./nix/oci/caddy {
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
      };

      clair = import ./nix/oci/clair {
        inherit pkgs;
        inherit crossPkgs;
      };

      cmake = import ./nix/oci/cmake {
        inherit pkgs;
        inherit crossPkgs;
      };

      #codestream-ci = import ./nix/oci/codestream-ci {
      #  inherit pkgs;
      #  inherit pkgsUnstable;
      #  inherit crossPkgs;
      #  inherit crossPkgsUnstable;
      #  #inherit pkgCodestreamCLI;
      #};

      codeql = import ./nix/oci/codeql {
        inherit pkgs;
        inherit crossPkgs;
      };

      cosign = import ./nix/oci/cosign {
        inherit pkgs;
        inherit crossPkgs;
      };

      flawfinder = import ./nix/oci/flawfinder {
        inherit pkgs;
        inherit crossPkgs;
      };

      gitleaks = import ./nix/oci/gitleaks {
        inherit pkgs;
        inherit crossPkgs;
      };

      gnumake = import ./nix/oci/gnumake {
        inherit pkgs;
        inherit crossPkgs;
      };

      gosec = import ./nix/oci/gosec {
        inherit pkgs;
        inherit crossPkgs;
      };

      govc = import ./nix/oci/govc {
        inherit pkgs;
        inherit crossPkgs;
      };

      grype = import ./nix/oci/grype {
        inherit pkgs;
        inherit crossPkgs;
      };

      hadolint = import ./nix/oci/hadolint {
        inherit pkgs;
        inherit crossPkgs;
      };

      hello = import ./nix/oci/hello {
        inherit pkgs;
        inherit crossPkgs;
      };

      helm = import ./nix/oci/helm {
        inherit pkgs;
        inherit crossPkgs;
      };

      hugo = import ./nix/oci/hugo {
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
      };

      # TODO: fix
      #idem = import ./nix/oci/idem {
      #  inherit nixpkgs;
      #  inherit pkgs;
      #  inherit system;
      #  inherit poetry2nix;
      #  inherit crossPkgs;
      #};

      kaniko = import ./nix/oci/kaniko {
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
      };

      kics = import ./nix/oci/kics {
        inherit pkgs;
        inherit crossPkgs;
      };

      kpack = import ./nix/oci/kpack {
        inherit pkgs;
        inherit crossPkgs;
      };

      kube-linter = import ./nix/oci/kube-linter {
        inherit pkgs;
        inherit crossPkgs;
      };

      kubectl = import ./nix/oci/kubectl {
        inherit pkgs;
        inherit crossPkgs;
      };

      kubesec = import ./nix/oci/kubesec {
        inherit pkgs;
        inherit crossPkgs;
      };

      license_finder = import ./nix/oci/license_finder {
        inherit pkgs;
        inherit crossPkgs;
      };

      #loopy = import ./nix/oci/loopy {
      #  inherit pkgs;
      #  inherit pkgsUnstable;
      #  inherit crossPkgs;
      #  inherit crossPkgsUnstable;
      #  inherit pkgLoopy;
      #};

      packer = import ./nix/oci/packer {
        inherit pkgs;
        inherit crossPkgs;
      };

      pivnet = import ./nix/oci/pivnet {
        inherit pkgs;
        inherit crossPkgs;
      };

      salt = import ./nix/oci/salt {
        inherit pkgs;
        inherit crossPkgs;
      };

      secretscanner = import ./nix/oci/secretscanner {
        inherit pkgs;
        inherit crossPkgs;
      };

      semgrep = import ./nix/oci/semgrep {
        inherit pkgs;
        inherit crossPkgs;
      };

      skopeo = import ./nix/oci/skopeo {
        inherit pkgs;
        inherit crossPkgs;
      };

      snyk = import ./nix/oci/snyk {
        inherit pkgs;
        inherit crossPkgs;
      };

      syft = import ./nix/oci/syft {
        inherit pkgs;
        inherit crossPkgs;
      };

      tanzu = import ./nix/oci/tanzu {
        inherit pkgs;
        inherit crossPkgs;
      };

      terraform = import ./nix/oci/terraform {
        inherit pkgs;
        inherit crossPkgs;
      };

      terraform-ls = import ./nix/oci/terraform-ls {
        inherit pkgs;
        inherit crossPkgs;
      };

      tflint = import ./nix/oci/tflint {
        inherit pkgs;
        inherit crossPkgs;
      };

      tfsec = import ./nix/oci/tfsec {
        inherit pkgs;
        inherit crossPkgs;
      };

      trivy = import ./nix/oci/trivy {
        inherit pkgs;
        inherit crossPkgs;
      };
    }));

    ###############
    # DevShells
    ###############
    devShells = flattenPackages (forAllSystems (buildPlatform: hostPlatform: let
      # Build Platform
      system = buildPlatform;
      pkgs = pkgsImportCrossSystem buildPlatform buildPlatform;
      pkgsUnstable = pkgsImportCrossSystemUnstable buildPlatform buildPlatform;

      # Host Platform
      crossPkgs = pkgsImportCrossSystem buildPlatform hostPlatform;
      crossPkgsUnstable = pkgsImportCrossSystemUnstable buildPlatform hostPlatform;
    in {
      devenv = import ./nix/devshells/devenv {
        inherit inputs;
        inherit system;
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
        inherit crossPkgsUnstable;
      };

      default = self.devShells."${system}.${system}".devenv;
    }));

    # Set the default devshell to the one for the current system.
    devShell = builtins.listToAttrs (map (system: {
        name = system;
        value = self.devShells."${system}.${system}".devenv;
      })
      supportedSystems);
  };
}

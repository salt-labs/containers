##################################################
# Notes:
#
#   # Build & run container
#   nix build --impure ".#${CONTAINER}"
#   docker load < result
#   docker run -it --rm ${CONTAINER}:latest
#   Examples: https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/docker/examples.nix
#
#   # Use devShell
#   nix develop
##################################################
{
  description = "Container images built with Nix";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-22.11";
      flake = true;
    };

    nixpkgs-unstable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixos-unstable";
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

    codestream-cli = {
      type = "github";
      owner = "salt-labs";
      repo = "codestream-cli";
      ref = "trunk";
      flake = true;
    };

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
    codestream-cli,
    loopy,
    ...
  } @ inputs: let
    inherit (self) outputs;

    system = "x86_64-linux";

    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    forAllSystems = f:
      builtins.listToAttrs (map (name: {
          inherit name;
          value = f name;
        })
        systems);

    pkgsImportSystem = system:
      import inputs.nixpkgs {
        inherit system;
      };

    pkgsImportSystemUnstable = system:
      import inputs.nixpkgs-unstable {inherit system;};

    pkgsImportCrossSystem = buildPlatform: hostPlatform:
      if buildPlatform == hostPlatform
      then
        import inputs.nixpkgs {
          system = buildPlatform;
          localSystem = buildPlatform;
          crossSystem = buildPlatform;
        }
      else
        import inputs.nixpkgs {
          system = buildPlatform;
          localSystem = buildPlatform;
          crossSystem = hostPlatform;
        };

    pkgsAllowUnfree = {
      nixpkgs = {
        config = {
          allowUnfree = true;
          allowUnfreePredicate = _: true;
        };
      };
    };
  in {
    packages = forAllSystems (hostPlatform: let
      # Build Platform
      inherit system;
      inherit (self.packages.${system}) default;
      pkgs = pkgsImportSystem system;
      pkgsUnstable = pkgsImportSystemUnstable system;

      # Host Platform
      inherit hostPlatform;
      crossPkgs = pkgsImportCrossSystem system hostPlatform;
      crossPkgsUnstable = pkgsImportCrossSystem system hostPlatform;

      # codestream-cli
      pkgCodestreamCLI = codestream-cli.packages.${hostPlatform}.codestream-cli;

      # Loopy
      pkgLoopy = loopy.packages.${hostPlatform}.loopy;
    in {
      brakeman = import ./oci/brakeman {
        inherit pkgs;
        inherit crossPkgs;
      };

      buildah = import ./oci/buildah {
        inherit pkgs;
        inherit crossPkgs;
      };

      carvel = import ./oci/carvel {
        inherit pkgs;
        inherit crossPkgs;
      };

      caddy = import ./oci/caddy {
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
      };

      clair = import ./oci/clair {
        inherit pkgs;
        inherit crossPkgs;
      };

      cmake = import ./oci/cmake {
        inherit pkgs;
        inherit crossPkgs;
      };

      #codestream-ci = import ./oci/codestream-ci {
      #  inherit pkgs;
      #  inherit pkgsUnstable;
      #  inherit crossPkgs;
      #  inherit crossPkgsUnstable;
      #  inherit pkgCodestreamCLI;
      #};

      codeql = import ./oci/codeql {
        inherit pkgs;
        inherit crossPkgs;
      };

      cosign = import ./oci/cosign {
        inherit pkgs;
        inherit crossPkgs;
      };

      flawfinder = import ./oci/flawfinder {
        inherit pkgs;
        inherit crossPkgs;
      };

      gitleaks = import ./oci/gitleaks {
        inherit pkgs;
        inherit crossPkgs;
      };

      gnumake = import ./oci/gnumake {
        inherit pkgs;
        inherit crossPkgs;
      };

      gosec = import ./oci/gosec {
        inherit pkgs;
        inherit crossPkgs;
      };

      govc = import ./oci/govc {
        inherit pkgs;
        inherit crossPkgs;
      };

      grype = import ./oci/grype {
        inherit pkgs;
        inherit crossPkgs;
      };

      hadolint = import ./oci/hadolint {
        inherit pkgs;
        inherit crossPkgs;
      };

      hello = import ./oci/hello {
        inherit pkgs;
        inherit crossPkgs;
      };

      helm = import ./oci/helm {
        inherit pkgs;
        inherit crossPkgs;
      };

      hugo = import ./oci/hugo {
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
      };

      # TODO: fix
      #idem = import ./oci/idem {
      #  inherit nixpkgs;
      #  inherit pkgs;
      #  inherit system;
      #  inherit poetry2nix;
      #  inherit crossPkgs;
      #};

      kaniko = import ./oci/kaniko {
        inherit pkgs;
        inherit pkgsUnstable;
        inherit crossPkgs;
      };

      kics = import ./oci/kics {
        inherit pkgs;
        inherit crossPkgs;
      };

      kpack = import ./oci/kpack {
        inherit pkgs;
        inherit crossPkgs;
      };

      kube-linter = import ./oci/kube-linter {
        inherit pkgs;
        inherit crossPkgs;
      };

      kubectl = import ./oci/kubectl {
        inherit pkgs;
        inherit crossPkgs;
      };

      kubesec = import ./oci/kubesec {
        inherit pkgs;
        inherit crossPkgs;
      };

      license_finder = import ./oci/license_finder {
        inherit pkgs;
        inherit crossPkgs;
      };

      #loopy = import ./oci/loopy {
      #  inherit pkgs;
      #  inherit pkgsUnstable;
      #  inherit crossPkgs;
      #  inherit crossPkgsUnstable;
      #  inherit pkgLoopy;
      #};

      packer = import ./oci/packer {
        inherit pkgs;
        inherit crossPkgs;
      };

      pivnet = import ./oci/pivnet {
        inherit pkgs;
        inherit crossPkgs;
      };

      salt = import ./oci/salt {
        inherit pkgs;
        inherit crossPkgs;
      };

      secretscanner = import ./oci/secretscanner {
        inherit pkgs;
        inherit crossPkgs;
      };

      semgrep = import ./oci/semgrep {
        inherit pkgs;
        inherit crossPkgs;
      };

      skopeo = import ./oci/skopeo {
        inherit pkgs;
        inherit crossPkgs;
      };

      snyk = import ./oci/snyk {
        inherit pkgs;
        inherit crossPkgs;
      };

      syft = import ./oci/syft {
        inherit pkgs;
        inherit crossPkgs;
      };

      tanzu = import ./oci/tanzu {
        inherit pkgs;
        inherit crossPkgs;
      };

      terraform = import ./oci/terraform {
        inherit pkgs;
        inherit crossPkgs;
      };

      terraform-ls = import ./oci/terraform-ls {
        inherit pkgs;
        inherit crossPkgs;
      };

      tflint = import ./oci/tflint {
        inherit pkgs;
        inherit crossPkgs;
      };

      tfsec = import ./oci/tfsec {
        inherit pkgs;
        inherit crossPkgs;
      };

      trivy = import ./oci/trivy {
        inherit pkgs;
        inherit crossPkgs;
      };
    });

    devShells = forAllSystems (system: let
      pkgs = pkgsImportSystem system;
    in {
      devenv = import ./devshells/devenv {
        inherit inputs;
        inherit pkgs;
      };
    });
  };
}

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

    # https://devenv.sh/
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
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    devenv,
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
      pkgs = pkgsImportSystem system;
      inherit (self.packages.${system}) default;

      # Host Platform
      inherit hostPlatform;
      crossPkgs = pkgsImportCrossSystem system hostPlatform;
    in {
      brakeman = import ./containers/brakeman {
        inherit pkgs;
      };

      buildah = import ./containers/buildah {
        inherit pkgs;
      };

      carvel = import ./containers/carvel {
        inherit pkgs;
      };

      ci = import ./containers/ci {
        inherit pkgs;
      };

      clair = import ./containers/clair {
        inherit pkgs;
      };

      cmake = import ./containers/cmake {
        inherit pkgs;
      };

      codeql = import ./containers/codeql {
        inherit pkgs;
      };

      cosign = import ./containers/cosign {
        inherit pkgs;
      };

      flawfinder = import ./containers/flawfinder {
        inherit pkgs;
      };

      gitleaks = import ./containers/gitleaks {
        inherit pkgs;
      };

      gnumake = import ./containers/gnumake {
        inherit pkgs;
      };

      gosec = import ./containers/gosec {
        inherit pkgs;
      };

      govc = import ./containers/govc {
        inherit pkgs;
      };

      grype = import ./containers/grype {
        inherit pkgs;
      };

      hadolint = import ./containers/hadolint {
        inherit pkgs;
      };

      hello = import ./containers/hello {
        inherit pkgs;
      };

      helm = import ./containers/helm {
        inherit pkgs;
      };

      #idem = import ./containers/idem {
      #  inherit pkgs;
      #};

      kics = import ./containers/kics {
        inherit pkgs;
      };

      kpack = import ./containers/kpack {
        inherit pkgs;
      };

      kube-linter = import ./containers/kube-linter {
        inherit pkgs;
      };

      kubectl = import ./containers/kubectl {
        inherit pkgs;
      };

      kubesec = import ./containers/kubesec {
        inherit pkgs;
      };

      license_finder = import ./containers/license_finder {
        inherit pkgs;
      };

      packer = import ./containers/packer {
        inherit pkgs;
      };

      pivnet = import ./containers/pivnet {
        inherit pkgs;
      };

      salt = import ./containers/salt {
        inherit pkgs;
      };

      secretscanner = import ./containers/secretscanner {
        inherit pkgs;
      };

      semgrep = import ./containers/semgrep {
        inherit pkgs;
      };

      skopeo = import ./containers/skopeo {
        inherit pkgs;
      };

      snyk = import ./containers/snyk {
        inherit pkgs;
      };

      syft = import ./containers/syft {
        inherit pkgs;
      };

      tanzu = import ./containers/tanzu {
        inherit pkgs;
      };

      terraform = import ./containers/terraform {
        inherit pkgs;
      };

      terraform-ls = import ./containers/terraform-ls {
        inherit pkgs;
      };

      tflint = import ./containers/tflint {
        inherit pkgs;
      };

      tfsec = import ./containers/tfsec {
        inherit pkgs;
      };

      trivy = import ./containers/trivy {
        inherit pkgs;
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

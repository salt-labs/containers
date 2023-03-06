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

    poetry2nix = {
      type = "github";
      owner = "nix-community";
      repo = "poetry2nix";
      ref = "master";
      flake = true;
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-unstable,
    devenv,
    poetry2nix,
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

      # Host Platform
      inherit hostPlatform;
      crossPkgs = pkgsImportCrossSystem system hostPlatform;
    in {
      brakeman = import ./oci/brakeman {
        inherit pkgs;
      };

      buildah = import ./oci/buildah {
        inherit pkgs;
      };

      carvel = import ./oci/carvel {
        inherit pkgs;
      };

      ci = import ./oci/ci {
        inherit pkgs;
      };

      clair = import ./oci/clair {
        inherit pkgs;
      };

      cmake = import ./oci/cmake {
        inherit pkgs;
      };

      codeql = import ./oci/codeql {
        inherit pkgs;
      };

      cosign = import ./oci/cosign {
        inherit pkgs;
      };

      flawfinder = import ./oci/flawfinder {
        inherit pkgs;
      };

      gitleaks = import ./oci/gitleaks {
        inherit pkgs;
      };

      gnumake = import ./oci/gnumake {
        inherit pkgs;
      };

      gosec = import ./oci/gosec {
        inherit pkgs;
      };

      govc = import ./oci/govc {
        inherit pkgs;
      };

      grype = import ./oci/grype {
        inherit pkgs;
      };

      hadolint = import ./oci/hadolint {
        inherit pkgs;
      };

      hello = import ./oci/hello {
        inherit pkgs;
      };

      helm = import ./oci/helm {
        inherit pkgs;
      };

      # TODO: fix
      #idem = import ./oci/idem {
      #  inherit nixpkgs;
      #  inherit pkgs;
      #  inherit system;
      #  inherit poetry2nix;
      #};

      kics = import ./oci/kics {
        inherit pkgs;
      };

      kpack = import ./oci/kpack {
        inherit pkgs;
      };

      kube-linter = import ./oci/kube-linter {
        inherit pkgs;
      };

      kubectl = import ./oci/kubectl {
        inherit pkgs;
      };

      kubesec = import ./oci/kubesec {
        inherit pkgs;
      };

      license_finder = import ./oci/license_finder {
        inherit pkgs;
      };

      packer = import ./oci/packer {
        inherit pkgs;
      };

      pivnet = import ./oci/pivnet {
        inherit pkgs;
      };

      salt = import ./oci/salt {
        inherit pkgs;
      };

      secretscanner = import ./oci/secretscanner {
        inherit pkgs;
      };

      semgrep = import ./oci/semgrep {
        inherit pkgs;
      };

      skopeo = import ./oci/skopeo {
        inherit pkgs;
      };

      snyk = import ./oci/snyk {
        inherit pkgs;
      };

      syft = import ./oci/syft {
        inherit pkgs;
      };

      tanzu = import ./oci/tanzu {
        inherit pkgs;
      };

      terraform = import ./oci/terraform {
        inherit pkgs;
      };

      terraform-ls = import ./oci/terraform-ls {
        inherit pkgs;
      };

      tflint = import ./oci/tflint {
        inherit pkgs;
      };

      tfsec = import ./oci/tfsec {
        inherit pkgs;
      };

      trivy = import ./oci/trivy {
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

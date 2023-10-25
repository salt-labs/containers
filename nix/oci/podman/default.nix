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

  environmentHelpers = with pkgs.dockerTools; [
    usrBinEnv
    binSh
    caCertificates
  ];

  stablePkgs = with pkgs; [
  ];

  unstablePkgs = with pkgsUnstable; [
  ];
in
  pkgs.dockerTools.buildLayeredImage {
    name = "podman";
    tag = "latest";
    created = creationDate;

    architecture = "amd64";

    fromImage = baseImage;
    maxLayers = 100;

    # Enable fakeRootCommands in a fake chroot environment.
    enableFakechroot = false;

    # Run these commands in the fake chroot environment.
    fakeRootCommands = ''
    '';

    # Runs in the final layer, on top of other layers.
    extraCommands = ''
    '';

    config = {
      User = containerUser;
      Labels = {
        "org.opencontainers.image.description" = "podman";
      };
      Cmd = [
        "/bin/bash"
      ];
    };
  }

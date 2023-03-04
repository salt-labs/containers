{pkgs, ...}: let
  product_name = "tanzu";
  product_version = "2.1.0";
  filename = "tanzu-cli-bundle-linux-amd64.tar.gz";
  checksum = "03c9b77e65ef8ba0b7d7b51df583fdb32d47171bcc8c1a67536aa2d2afad9f0a";
  homepage = "https://customerconnect.vmware.com/downloads/details?downloadGroup=TKG-210&productId=1400";
in
  pkgs.stdenv.mkDerivation {
    name = product_name;
    version = product_version;

    src = pkgs.requireFile {
      name = filename;
      sha256 = checksum;

      message = ''
        In order to use VMware Tanzu Kubernetes Grid, you need to accept the EULA and download the file from:

        ${homepage}

        Once you have downloaded the file, please use the following command and re-run the installation:

        nix-prefetch-url file://\$PWD/${filename}
      '';
    };

    dontBuild = true;
    dontConfigure = true;
    sourceRoot = ".";
    preferLocalBuild = true;

    phases = ["unpackPhase" "installPhase"];

    unpackPhase = ''
      mkdir --parents unpack

      tar -xzf $src -C unpack
    '';

    installPhase = ''
      mkdir --parents $out/bin

      source=unpack/cli/core/*/tanzu-core-linux_amd64

      install --verbose $source $out/bin/tanzu
    '';

    meta = {
      description = "VMware Tanzu Kubernetes Grid CLI";
      homepage = "https://vmware.com";
      license = "Commercial";
    };
  }

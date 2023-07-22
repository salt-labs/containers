# NOTE: Cachix push
# nix build --json --impure ".#packages.\"x86_64-linux.x86_64-linux\".tanzu" | jq -r '.[0].outputs.out' | cachix push salt-labs
{pkgs, ...}: let
  # The Tanzu CLI is now de-coupled from TKG.
  product_name = "tanzu-cli";
  product_version = "0.90.1";
  filename = "tanzu-cli-linux-amd64.tar.gz";
  checksum = "fec9e268399443de94d1761678aa39be18b7b685dd34a4412933943647b9d0be";
  homepage = "https://customerconnect.vmware.com/downloads/details?downloadGroup=TCLI-0901&productId=1431";
in
  pkgs.stdenv.mkDerivation {
    name = product_name;
    version = product_version;

    src = pkgs.requireFile {
      name = filename;
      sha256 = checksum;

      message = ''
        In order to use VMware Tanzu CLI, you need to accept the EULA and download the file from:

        ${homepage}

        Once you have downloaded the file, please use the following command and re-run the installation:

        nix-prefetch-url file://\$PWD/${filename}
        nix-hash --type sha256 --flat --base32 ${filename}
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

      source=unpack/*/tanzu-cli-linux_amd64

      install --verbose $source $out/bin/tanzu
    '';

    meta = {
      description = "VMware Tanzu CLI";
      homepage = "https://vmware.com";
      license = "Commercial";
    };
  }

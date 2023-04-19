{
  pkgs,
  crossPkgs,
  ...
}: let
  product_name = "tanzu";
  product_version = "1.6.1";
  filename = "tanzu-cli-bundle-linux-amd64.tar.gz";
  checksum = "e096d83a754fe5e81b831791f5fa7e4a239f0baecbe14eaf3c71373ae2b75265";
  homepage = "https://customerconnect.vmware.com/downloads/details?downloadGroup=TKG-161&productId=1162";
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

        If you are using cachix,
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

      install --verbose $source $out/bin/tanzu-${product_version}
    '';

    meta = {
      description = "VMware Tanzu Kubernetes Grid CLI";
      homepage = "https://vmware.com";
      license = "Commercial";
    };
  }

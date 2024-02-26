# NOTE: Cachix push
# nix build --json --impure ".#packages.\"x86_64-linux.x86_64-linux\".tanzu" | jq -r '.[0].outputs.out' | cachix push salt-labs
# https://github.com/vmware-tanzu/tanzu-cli
{pkgs, ...}: let
  version = "1.2.0";

  tanzu-cli = {
    core = pkgs.fetchurl {
      name = "tanzu-cli";
      url = "https://github.com/vmware-tanzu/tanzu-cli/releases/download/v${version}/tanzu-cli-linux-amd64.tar.gz";
      sha256 = "sha256-8ZI9VR/5ue/zoDnZSGJ6QaoK6/dofL/YCZAVA1Za43U=";
    };

    plugins = pkgs.fetchurl {
      name = "tanzu-cli-plugins";
      url = "https://github.com/vmware-tanzu/tanzu-cli/releases/download/v${version}/tanzu-plugins-admin-linux-amd64.tar.gz";
      sha256 = "sha256-4ButVE6N1l0pTz9cZ+QLlKGEhvWMLzLHiTmk1GXI6Ic=";
    };
  };
in
  pkgs.stdenv.mkDerivation {
    name = "tanzu-cli";
    version = version;

    dontBuild = true;
    dontConfigure = true;
    sourceRoot = ".";
    preferLocalBuild = true;

    phases = ["unpackPhase" "installPhase"];

    unpackPhase = ''
      mkdir --parents unpack

      tar -xzf ${tanzu-cli.core} -C unpack

      tar -xvf ${tanzu-cli.plugins} -C unpack
    '';

    installPhase = ''
      mkdir --parents $out/usr/local/bin
      mkdir --parents $out/usr/local/share/applications/tanzu-cli/plugins

      CORE=unpack/*/tanzu-cli-linux_amd64
      PLUGINS=unpack/admin-plugins-*

      install --mode=0755 --verbose $CORE $out/usr/local/bin/tanzu

      cp -r $PLUGINS $out/usr/local/share/applications/tanzu-cli/plugins
    '';

    meta = {
      description = "Command line interface for Tanzu Kubernetes Grid.";
      homepage = "https://github.com/vmware-tanzu/tanzu-cli";
      license = "Apache 2.0";
    };
  }

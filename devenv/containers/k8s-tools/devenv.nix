{pkgs, ...}: let

  oci_name = "k8s-tools";
  oci_version = "latest";

in {

  containers = {

    hello = {

      isBuilding = true;

      name = hello;

      version = oci_version;

      maxLayers = 1;

      copyToRoot = with pkgs; [
        hello
      ];

      entrypoint = with pkgs; [
        hello
      ];

      startupCommand = pkgs.hello;

    };

  };

}

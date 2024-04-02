{pkgs, ...}: let

  oci_name = "k8s-tools";
  oci_version = "latest";

in {

  containers = {

    oci_name = {

      isBuilding = true;

      name = oci_name;

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

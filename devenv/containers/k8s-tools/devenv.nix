{pkgs, ...}: let

  oci_name = "k8s-tools";
  oci_version = "latest";

in {

  containers = {

    "k8s-tools" = {

      isBuilding = true;

      name = "k8s-tools";

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

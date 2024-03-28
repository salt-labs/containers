{pkgs, ...}: let
  oci_name = "test";
  oci_version = "latest";
in {
  containers = {
    "${oci_name}" = {
      isBuilding = true;

      name = "${oci_name}";

      version = oci_version;

      maxLayers = 1;

      registry = null;

      copyToRoot = with pkgs; [
        hello
      ];

      entrypoint = with pkgs; [
        hello
      ];

      startupCommand = null;

      # Default arguments for Skopeo
      defaultCopyArgs = [
      ];
    };
  };
}

{pkgs, ...}: let
  oci_name = "k8s-tools";
  oci_version = "latest";
  oci_registry = "docker://ghcr.io/salt-labs.containers/";
  oci_registry_user = "";
  oci_registry_pass = "";
in {
  containers = {
    "${oci_name}" = {
      isBuilding = true;

      name = "${oci_name}";

      version = oci_version;

      maxLayers = 1;

      registry = "${oci_registry}";

      copyToRoot = with pkgs; [
        hello
      ];

      entrypoint = with pkgs; [
        hello
      ];

      startupCommand = null;

      # Default arguments for Skopeo
      defaultCopyArgs = [
        "--dest-creds"
        "${oci_registry_user}:${oci_registry_pass}"
      ];
    };
  };
}

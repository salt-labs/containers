{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "ci";
  tag = "latest";
  created = "now";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    pathsToLink = ["/bin"];

    paths = with pkgs; [
      # Common
      busybox
      curlFull
      cacert

      # Tools
      git
      jq
      unzip
      wget
      yq
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "DESCRIPTION";
    };
    Entrypoint = [
      "${pkgs.busybox}/bin/sh"
    ];
    Cmd = [
    ];
    ExposedPorts = {
    };
    Env = [
      "SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
    ];
    WorkingDir = "/workdir";
  };
}

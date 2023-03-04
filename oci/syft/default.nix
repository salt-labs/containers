{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "syft";
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
      syft
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "syft";
    };
    Entrypoint = [
      "${pkgs.syft}/bin/syft"
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

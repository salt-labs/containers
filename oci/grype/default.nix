{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "grype";
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
      grype
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "DESCRIPTION";
    };
    Entrypoint = [
      "${pkgs.grype}/bin/grype"
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

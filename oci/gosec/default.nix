{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "gosec";
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
      gosec
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "gosec";
    };
    Entrypoint = [
      "${pkgs.gosec}/bin/gosec"
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

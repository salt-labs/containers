{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "tflint";
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
      tflint
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "tflint";
    };
    Entrypoint = [
      "${pkgs.tflint}/bin/tflint"
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

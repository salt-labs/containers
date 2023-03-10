{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "hadolint";
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
      hadolint
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "hadolint";
    };
    Entrypoint = [
      "${pkgs.hadolint}/bin/hadolint"
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

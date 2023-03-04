{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "brakeman";
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
      brakeman
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "Brakeman";
    };
    Entrypoint = [
      "${pkgs.brakeman}/bin/brakeman"
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

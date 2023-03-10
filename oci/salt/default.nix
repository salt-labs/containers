{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "salt";
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
      salt
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "salt";
    };
    Entrypoint = [
      "${pkgs.salt}/bin/salt"
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

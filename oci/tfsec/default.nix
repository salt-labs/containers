{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "tfsec";
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
      tfsec
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "tfsec";
    };
    Entrypoint = [
      "${pkgs.tfsec}/bin/tfsec"
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

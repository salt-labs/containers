{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "gitleaks";
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
      gitleaks
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "Gitleaks";
    };
    Entrypoint = [
      "${pkgs.gitleaks}/bin/gitleaks"
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

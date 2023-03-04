{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "snyk";
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
      nodePackages.snyk
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "DESCRIPTION";
    };
    Entrypoint = [
      "${pkgs.nodePackages.snyk}/bin/snyk"
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

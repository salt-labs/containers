{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "codeql";
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
      codeql
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "CodeQL";
    };
    Entrypoint = [
      "${pkgs.codeql}/bin/codeql"
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

{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "template";
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
      template
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "DESCRIPTION";
    };
    Entrypoint = [
      "${pkgs.template}/bin/template"
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

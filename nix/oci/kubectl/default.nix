{
  pkgs,
  crossPkgs,
  ...
}:
pkgs.dockerTools.buildImage {
  name = "kubectl";
  tag = "latest";
  #created = "now";

  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    pathsToLink = ["/bin"];

    paths = with pkgs; [
      # Common
      busybox
      curlFull
      cacert

      # Tools
      kubectl
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "kubectl";
    };
    Entrypoint = [
      "${pkgs.kubectl}/bin/kubectl"
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

{
  pkgs,
  crossPkgs,
  ...
}:
pkgs.dockerTools.buildImage {
  name = "kube-linter";
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
      kube-linter
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "kube-linter";
    };
    Entrypoint = [
      "${pkgs.kube-linter}/bin/kube-linter"
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

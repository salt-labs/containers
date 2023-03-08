{
  pkgs,
  crossPkgs,
  ...
}:
pkgs.dockerTools.buildImage {
  name = "kics";
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
      kics
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "kics";
    };
    Entrypoint = [
      "${pkgs.kics}/bin/kics"
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

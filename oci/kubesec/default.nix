{
  pkgs,
  crossPkgs,
  ...
}:
pkgs.dockerTools.buildImage {
  name = "kubesec";
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
      kubesec
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "kubesec";
    };
    Entrypoint = [
      "${pkgs.kubesec}/bin/kubesec"
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

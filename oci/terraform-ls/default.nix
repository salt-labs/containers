{pkgs, ...}:
pkgs.dockerTools.buildImage {
  name = "terraform-ls";
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
      terraform-ls
    ];
  };

  config = {
    Labels = {
      "org.opencontainers.image.description" = "DESCRIPTION";
    };
    Entrypoint = [
      "${pkgs.terraform-ls}/bin/terraform-ls"
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

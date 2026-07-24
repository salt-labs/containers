{ pkgs, inputs, ... }: {
  devenv = {
    flakesIntegration = true;
  };

  task.package = pkgs.lib.mkDefault (
    inputs.devenv.packages.${pkgs.stdenv.system}.devenv-tasks or pkgs.hello
  );
}

{
  inputs,
  pkgs,
  ...
}: (
  import ./nix/devshells/devenv {
    inherit inputs;
    inherit pkgs;
  }
)

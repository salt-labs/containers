{writeShellScriptBin}: let
  wrapper = builtins.readFile ./wrapper.sh;
  wrapperFunctionsCommon = builtins.readFile ./functions.sh;
in
  writeShellScriptBin "entrypoint" (
    wrapperFunctionsCommon
    + wrapper
  )

{writeShellScriptBin}: let
  wrapper = builtins.readFile ./wrapper.sh;
  wrapperFunctionsCommon = builtins.readFile ./functions.sh;
  wrapperFunctionsBinaries = builtins.readFile ./binaries.sh;
in
  writeShellScriptBin "codestream-ci" (
    wrapperFunctionsCommon
    + wrapperFunctionsBinaries
    + wrapper
  )

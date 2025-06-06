{ pkgs, ... }:

let
  # Read all files in this directory
  files = builtins.readDir ./.;

  # Filter only .nix files except default.nix itself
  nixFiles = builtins.filter
    (f: builtins.match ".*\\.nix" f != null && f != "default.nix")
    (builtins.attrNames files);

  # Import each nix file as an attribute named after the file (without .nix)
  imports = builtins.listToAttrs (map (fileName: {
    name = builtins.substring 0 (builtins.stringLength fileName - 4) fileName;
    value = import (./${fileName}) { inherit pkgs; };
  }) nixFiles);
in
imports

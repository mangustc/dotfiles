{ lib, ... }:

let
	entries = builtins.readDir ./.;
	nixFiles = lib.filterAttrs (name: _: lib.hasSuffix ".nix" name && name != "default.nix") entries;
	imports = lib.attrValues (lib.mapAttrs (name: _: import (./${name})) nixFiles);
in {
	imports = imports;
}


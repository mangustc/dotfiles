
{ config, lib, pkgs, ... }:

let
	modulename = "distrobox";
	cfg = config.modules.${modulename};

in {
	options.modules.${modulename} = {
		enable = lib.mkEnableOption "Enable ${modulename}";
	};

	config = lib.mkIf cfg.enable {
		virtualisation.podman = {
			enable = true;
			dockerCompat = true;
		};
		environment.systemPackages = with pkgs; [
			distrobox
		];
	};
}


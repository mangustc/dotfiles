{ config, lib, pkgs, ... }:

let
	cfg = config.modules.plasma;
in {
	options.modules.plasma = {
		enable = lib.mkEnableOption "Enable plasma";
	};

	config = lib.mkIf cfg.enable {
		services.desktopManager.plasma6.enable = true;
		programs.kdeconnect.enable = true;
		environment.plasma6.excludePackages = with pkgs; [
			kdePackages.discover
			kdePackages.krdp
			kdePackages.elisa
			kdePackages.konsole
			kdePackages.khelpcenter
		];
		programs.dconf.enable = true;
		services.power-profiles-daemon.enable = false;
		networking.networkmanager.enable = false;
		hardware.bluetooth.enable = false;
		environment.systemPackages = with pkgs; [
		];
		fonts.packages = with pkgs; [
		];
	};
}

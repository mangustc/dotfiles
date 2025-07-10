{ config, lib, pkgs, ... }:

let
	cfg = config.modules.plasma;
in {
	options.modules.plasma = {
		enable = lib.mkEnableOption "Enable plasma";
	};

	config = lib.mkIf cfg.enable {
		services.desktopManager.plasma6.enable = true;
		environment.plasma6.excludePackages = with pkgs; [
			kdePackages.discover
			kdePackages.krdp
			kdePackages.elisa
			kdePackages.konsole
			kdePackages.khelpcenter
		];
		programs.dconf.enable = true;

		# plasma should only configure the desktop environment
		services.power-profiles-daemon.enable = lib.mkDefault false;
		networking.networkmanager.enable = lib.mkDefault false;
		hardware.bluetooth.enable = lib.mkDefault false;

		environment.systemPackages = with pkgs; [
			maliit-keyboard
		];
		fonts.packages = with pkgs; [
		];
	};
}

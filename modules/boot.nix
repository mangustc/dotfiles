{ config, lib, pkgs, ... }:

let
	cfg = config.modules.boot;
in {
	options.modules.boot = {
		enable = lib.mkEnableOption "Enable boot loader";
		secureBoot.enable = lib.mkEnableOption "Enable secure boot";
	};

	config = lib.mkIf cfg.enable {
		boot = if cfg.secureBoot.enable then {
			lanzaboote = {
				enable = true;
				pkiBundle = "/var/lib/sbctl";
			};
			loader.systemd-boot.enable = lib.mkForce false;
			loader.efi.canTouchEfiVariables = true;
			kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
			blacklistedKernelModules = [
				"pcspkr"
				"iTCO_wdt"
			];
			kernelParams = [
				"nowatchdog"
			];
		} else {
			loader.systemd-boot.enable = true;
			loader.efi.canTouchEfiVariables = true;
			kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
			blacklistedKernelModules = [
				"pcspkr"
				"iTCO_wdt"
			];
			kernelParams = [
				"nowatchdog"
			];
		};
		environment.systemPackages = with pkgs; lib.mkIf cfg.secureBoot.enable [
			sbctl
		];
	};
}


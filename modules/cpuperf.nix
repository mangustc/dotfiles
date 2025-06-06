{ config, lib, pkgs, ... }:

let
	cfg = config.modules.cpuperf;
	myPkgs = (import ../myPkgs pkgs);
in {
	options.modules.cpuperf = {
		enable = lib.mkEnableOption "Enable cpuperf";
	};

	config = lib.mkIf cfg.enable {
		environment.systemPackages = [
			myPkgs.cpuperf
		];
		services.udev.extraRules = ''
SUBSYSTEM=="cpu", ACTION=="add", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/system/cpu/%k/cpufreq/scaling_governor", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/system/cpu/%k/cpufreq/energy_performance_preference", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/devices/system/cpu/%k/cpufreq/scaling_governor", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/devices/system/cpu/%k/cpufreq/energy_performance_preference"
		'';
	};
}

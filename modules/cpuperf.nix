{ config, lib, pkgs, ... }:

let
	cfg = config.modules.cpuperf;
in {
	options.modules.cpuperf = {
		enable = lib.mkEnableOption "Enable cpuperf";
	};

	config = lib.mkIf cfg.enable {
		environment.systemPackages = [
			(pkgs.writeShellScriptBin "cpuperf" ''
if [ "$1" = "performance" ]; then
	echo "Enabling performance mode..."
	echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
elif [ "$1" = "powersave" ]; then
	echo "Enable powersave mode..."
	echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
	echo balance_performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
else
	echo "Usage: $0 {perforamnce|powersave}"
fi
			'')
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

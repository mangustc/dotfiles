{ pkgs, ... }:
pkgs.stdenv.mkDerivation rec {
  pname = "cpuperf";
  version = "1.0";
  src = pkgs.writeShellScriptBin pname ''
export PATH="${pkgs.kdePackages.kconfig}/bin:$PATH"
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
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${src}/bin/${pname} $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';
}


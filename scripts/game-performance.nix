{ pkgs, ... }:

let
	script = pkgs.writeShellScriptBin "game-performance" ''
export LD_PRELOAD=""
export DXVK_FILTER_DEVICE_NAME="NVIDIA"
export VKD3D_FILTER_DEVICE_NAME="NVIDIA"

if [ "$GP_NO_WRAPPER" == "1" ]; then
	systemctl start scx.service
	cpuperf performance
	exec "$@"
else
	systemctl start scx.service
	cpuperf performance
	"$@"
	cpuperf powersave
	systemctl stop scx.service
fi
	'';
in [
	script
]


{ pkgs, ... }:

let
	script = pkgs.writeShellScriptBin "game-performance" ''
export LD_PRELOAD=""
export DXVK_FILTER_DEVICE_NAME="NVIDIA"
export VKD3D_FILTER_DEVICE_NAME="NVIDIA"

systemctl start scx.service
cpuperf performance
"$@"
cpuperf powersave
systemctl stop scx.service
	'';
in [
	script
]


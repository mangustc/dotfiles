{ config, lib, pkgs, ... }:

let
	cfg = config.modules.gaming;
in {
	options.modules.gaming = {
		enable = lib.mkEnableOption "Enable gaming";
	};

	config = lib.mkIf cfg.enable {
		security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
	(action.lookup("unit") == "scx.service") &&
	subject.user == "ivan") {
      return polkit.Result.YES;
    }
  });
		'';
		services.scx = {
			enable = true;
			scheduler = "scx_lavd";
			extraArgs = [ "--performance" ];

		};
		systemd.services.scx.wantedBy = lib.mkForce [];
		environment.systemPackages = with pkgs; [
			(pkgs.writeShellScriptBin "killsteamgame" ''
${pkgs.killall}/bin/killall GameThread
			'')
			(pkgs.writeShellScriptBin "game-performance" ''
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
			'')
		];
	};
}

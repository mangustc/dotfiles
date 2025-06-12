{ config, lib, pkgs, ... }:

let
	cfg = config.modules.networking;
in {
	options.modules.networking = {
		enable = lib.mkEnableOption "Enable networking";
		wireless.enable = lib.mkEnableOption "Enable wireless";
		nethandler.enable = lib.mkEnableOption "Enable nethandler";
	};

	config = lib.mkIf cfg.enable {
		networking = {
			wireless.iwd = lib.mkIf cfg.wireless.enable {
				enable = true;
				settings = {
					Settings = {
						AutoConnect = true;
					};
				};
			};
			hostName = "nixos";
			firewall.enable = false;
			nftables = lib.mkIf cfg.nethandler.enable {
				enable = true;
				flushRuleset = true;
				ruleset = ''
table ip nethandler {
	chain INPUT {
		type filter hook input priority filter; policy accept;
		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter packets 1 bytes 36 queue flags bypass to 200
	}

	chain FORWARD {
		type filter hook forward priority filter; policy accept;
		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter packets 0 bytes 0 queue flags bypass to 200
	}

	chain OUTPUT {
		type filter hook output priority filter; policy accept;
		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter packets 2 bytes 96 queue flags bypass to 200
	}
}
				'';
			};
		};
		systemd.services.nethandler = lib.mkIf cfg.nethandler.enable {
			enable = true;
			description = "Nethandler";
			wantedBy = [ "default.target" ];
			serviceConfig = {
				ExecStart = pkgs.writeShellScript "nethandler" (builtins.readFile ./nethandler);
			};
		};
		security.polkit.extraConfig = lib.mkIf cfg.nethandler.enable ''
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (action.lookup("unit") == "nethandler.service") &&
        subject.user == "ivan") {
      return polkit.Result.YES;
    }
  });
		'';
		environment.systemPackages = with pkgs; if cfg.nethandler.enable then [
			libnetfilter_queue
		] else [
		];
	};
}


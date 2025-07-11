{ config, lib, pkgs, ... }:

let
	cfg = config.modules.nethandler;
in {
	options.modules.nethandler = {
		enable = lib.mkEnableOption "Enable nethandler";
		user = lib.mkOption {
			description = "User that can access the nethandler.service";
			type = lib.types.str;
		};
	};

	config = lib.mkIf cfg.enable {
		networking = {
			firewall.enable = false;
			nftables = {
				enable = true;
				flushRuleset = true;
				ruleset = ''
table ip filter {
	chain INPUT {
		type filter hook input priority filter; policy accept;
		
		# ignore local packets
                ip daddr 127.0.0.1 counter accept
                ip saddr 127.0.0.1 counter accept

		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter queue flags bypass to 200
	}

	chain FORWARD {
		type filter hook forward priority filter; policy accept;

		# ignore local packets
                ip daddr 127.0.0.1 counter accept
                ip saddr 127.0.0.1 counter accept

		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter queue flags bypass to 200
	}

	chain OUTPUT {
		type filter hook output priority filter; policy accept;

		# ignore local packets
                ip daddr 127.0.0.1 counter accept
                ip saddr 127.0.0.1 counter accept

		ct original packets 1-6 meta mark & 0x40000000 != 0x40000000 counter queue flags bypass to 200
	}
}
				'';
			};
		};
		systemd.services.nethandler = {
			enable = true;
			description = "Nethandler";
			wantedBy = [ "default.target" ];
			serviceConfig = {
				ExecStart = "/home/nethandler/nethandler";
			};
		};
		security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (action.lookup("unit") == "nethandler.service") &&
        subject.user == "${cfg.user}") {
      return polkit.Result.YES;
    }
  });
		'';
		environment.systemPackages = with pkgs; [
		];
	};
}


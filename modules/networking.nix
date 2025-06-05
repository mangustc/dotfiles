{ config, lib, pkgs, ... }:

let
	cfg = config.modules.networking;
in {
	options.modules.networking = {
		enable = lib.mkEnableOption "Enable networking";
		wireless.enable = lib.mkEnableOption "Enable wireless";
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
			firewall.enable = false;
			nftables = {
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
			hostName = "nixos";
		};
		systemd.services.nethandler = {
			enable = true;
			description = "Nethandler";
			wantedBy = [ "default.target" ];
			serviceConfig = {
				ExecStart = pkgs.writeShellScript "nethandler" (builtins.readFile ./nethandler);
			};
		};
		environment.systemPackages = with pkgs; [
			libnetfilter_queue
		];
	};
}


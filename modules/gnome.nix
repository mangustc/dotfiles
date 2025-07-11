{ config, lib, pkgs, ... }:

let
	cfg = config.modules.gnome;
in {
	options.modules.gnome = {
		enable = lib.mkEnableOption "Enable gnome";
	};

	config = lib.mkIf cfg.enable {
		services.desktopManager.gnome.enable = true;
		programs.dconf = {
			enable = true;
			profiles.user.databases = [
				{
					lockAll = true;
					settings = {
						"org/gnome/nautilus/preferences" = {
							default-folder-viewer = "list-view";
						};
						"org/gnome/nautilus/list-view" = {
							default-zoom-level = "small";
						};
						"org/gnome/Console" = {
							custom-font = "JetBrainsMono Nerd Font Semi-Bold 13";
							use-system-font = false;
							audible-bell = false;
							visual-bell = false;
						};
						"org/gnome/shell" = {
							disable-user-extensions = false;
							enabled-extensions = with pkgs.gnomeExtensions; [
								forge.extensionUuid
								gsconnect.extensionUuid
							];
						};
						"org/gnome/shell/extensions/forge/keybindings" = {
							window-toggle-float = [ "<Super>v" ];
							window-toggle-always-float = [ "<Shift><Super>v" ];
							con-split-vertical = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							con-stacked-layout-toggle = [ "<Shift><Super>p" ];
						};
						"org/gnome/shell/extensions/forge".window-gap-hidden-on-single = true;
						"org/gnome/desktop/interface" = {
							# font-name = "JetBrainsMono Nerd Font Semi-Bold 10";
							# document-font-name = "JetBrainsMono Nerd Font Semi-Bold 10";
							# monospace-font-name = "JetBrainsMono Nerd Font Semi-Bold 10";
							accent-color = "green";
							color-scheme = "prefer-dark";
							enable-animations = false;
							clock-format = "12h";
						};
						# "org/gnome/desktop/peripherals/mouse" = {
						# 	speed = -0.8;
						# 	accel-profile = "flat";
						# };
						"org/gnome/desktop/peripherals/keyboard" = {
							delay = lib.gvariant.mkUint32 300;
							repeat-interval = lib.gvariant.mkUint32 20;
						};
						"org/gnome/desktop/wm/preferences" = {
							focus-mode = "sloppy";
							num-workspaces = lib.gvariant.mkInt32 9;
						};
						"org/gnome/mutter".dynamic-workspaces = false;
						"org/gnome/settings-daumon/plugins/power" = {
							sleep-inactive-ac-type = "nothing";
						};
						"org/gnome/desktop/session" = {
							idle-delay = lib.gvariant.mkUint32 0;
						};
						"org/gnome/shell/keybindings" = {
							toggle-message-tray = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							show-screenshot-ui = [ "Print" "<Shift><Super>s" ];
							switch-to-application-1 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-2 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-3 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-4 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-5 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-6 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-7 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-8 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							switch-to-application-9 = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							toggle-application-view = [ "<Super>p" ];
						};
						"org/gnome/settings-daemon/plugins/media-keys" = {
							help = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							custom-keybindings = [
								"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
								"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
								"/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
							];
						};
						"org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
							name = "kgx";
							command = "kgx";
							binding = "<Super>t";
						};
						"org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
							name = "chlayout gaming";
							command = "chlayout gaming";
							binding = "<Super>F9";
						};
						"org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
							name = "chlayout default";
							command = "chlayout default";
							binding = "<Super>F8";
						};
						"org/gnome/desktop/wm/keybindings" = {
							minimize = lib.gvariant.mkEmptyArray (lib.gvariant.type.string);
							toggle-fullscreen = [ "<Super>f" ];
							close = [ "<Super>c" ];
							switch-to-workspace-1 = [ "<Super>1" ];
							switch-to-workspace-2 = [ "<Super>2" ];
							switch-to-workspace-3 = [ "<Super>3" ];
							switch-to-workspace-4 = [ "<Super>4" ];
							switch-to-workspace-5 = [ "<Super>5" ];
							switch-to-workspace-6 = [ "<Super>6" ];
							switch-to-workspace-7 = [ "<Super>7" ];
							switch-to-workspace-8 = [ "<Super>8" ];
							switch-to-workspace-9 = [ "<Super>9" ];
							move-to-workspace-1 = [ "<Shift><Super>1" ];
							move-to-workspace-2 = [ "<Shift><Super>2" ];
							move-to-workspace-3 = [ "<Shift><Super>3" ];
							move-to-workspace-4 = [ "<Shift><Super>4" ];
							move-to-workspace-5 = [ "<Shift><Super>5" ];
							move-to-workspace-6 = [ "<Shift><Super>6" ];
							move-to-workspace-7 = [ "<Shift><Super>7" ];
							move-to-workspace-8 = [ "<Shift><Super>8" ];
							move-to-workspace-9 = [ "<Shift><Super>9" ];
						};
					};
				}
			];
		};
		environment.gnome.excludePackages = with pkgs; [
			orca
			geary
			gnome-disk-utility
			baobab
			gnome-backgrounds
			gnome-tour
			gnome-user-docs
			epiphany
			gnome-calculator
			gnome-calendar
			gnome-characters
			gnome-contacts
			gnome-font-viewer
			gnome-maps
			gnome-weather
			gnome-connections
			snapshot
			totem
			yelp
			gnome-software
		];
		environment.systemPackages = with pkgs; [
			gnomeExtensions.forge
			gnomeExtensions.gsconnect
		];
		fonts.packages = with pkgs; [
			nerd-fonts.jetbrains-mono
		];
		services.power-profiles-daemon.enable = lib.mkOverride 999 false;
		networking.networkmanager.enable = lib.mkOverride 999 false;
		hardware.bluetooth.enable = lib.mkOverride 999 false;
		services.gnome.gcr-ssh-agent.enable = lib.mkOverride 999 false;
	};
}

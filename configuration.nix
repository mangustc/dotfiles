{ config, lib, pkgs, host, ... }:

let
	mh = "main";
	gh = "gaming";
	getByHost = first: second:
		if host.name == mh then first
		else if host.name == gh then second
		else throw "Unsupported host: ${host.name}";
	myPkgs = import ./myPkgs pkgs;
in {
	nix = {
		settings = {
			experimental-features = ["nix-command" "flakes"];
			auto-optimise-store = true;
		};
	};
	nixpkgs.config.allowUnfree = true;

	imports = [
		./hardware-configuration-${host.name}.nix
		./modules
	];

	modules.boot = {
		enable = true;
		secureBoot.enable = getByHost true false;
	};
	boot = lib.mkIf (host.name == "gaming") {
		kernelParams = [
			"nvidia.NVreg_UsePageAttributeTable=1"
			"nvidia.NVreg_DynamicPowerManagement=0"
			"nvidia.Nvreg_PreserveVideoMemoryAllocations=1"
		];
	};

	modules.networking = {
		enable = true;
		wireless.enable = getByHost true false;
	};
	time.timeZone = "Asia/Tomsk";
	i18n.defaultLocale = "en_US.UTF-8";
	console.keyMap = "dvorak";

	hardware = {
		graphics.enable = true;
		graphics.enable32Bit = true;
		nvidia = getByHost {
		} {
			powerManagement.enable = false;
			powerManagement.finegrained = false;
			open = false;
			nvidiaSettings = true;
			package = config.boot.kernelPackages.nvidiaPackages.stable;
		};
	};

	modules.flatpak = {
		enable = true;
		desiredFlatpaks = [
			"com.discordapp.Discord"
		];
	};
	services = {
		xserver = {
			enable = true;
			xkb = {
				layout = "us,ru";
				variant = "dvorak,";
				options = "grp:caps_toggle,terminate:ctrl_alt_bksp";
			};
			videoDrivers = getByHost [ "amdgpu" ] [ "nvidia" ];
			displayManager.lightdm.enable = lib.mkForce false;
		};
		desktopManager = {
			plasma6.enable = getByHost false true;
		};
		displayManager.ly = {
			enable = true;
			settings = {
				animation = "doom";
			};
		};
		pipewire = {
			enable = true;
			pulse.enable = true;
			extraConfig.pipewire-pulse = {
				"00-crackling-fix" = {
					"pulse.properties" = {
						"pulse.min.req" = "1024/48000";
						"pulse.min.frag" = "1024/48000";
						"pulse.min.quantum" = "1024/48000";
					};
				};
			};
		};
		tlp.enable = getByHost true false;
		sunshine = {
			enable = getByHost false true;
			autoStart = false;
			capSysAdmin = true;
			openFirewall = true;
		};
	};
	environment.plasma6.excludePackages = with pkgs; [
		kdePackages.discover
		kdePackages.krdp
		kdePackages.elisa
		kdePackages.konsole
		kdePackages.khelpcenter
	];


	users.defaultUserShell = pkgs.bash;
	users.users.ivan = {
		isNormalUser = true;
		extraGroups = [
			"wheel"
			"audio"
			"video"
			"input"
			"tty"
		];
		useDefaultShell = true;
	};

	modules.neovim.enable = true;
	modules.firefox.enable = true;
	modules.fish.enable = true;
	modules.hyprland.enable = getByHost true false;
	modules.kitty.enable = true;
	modules.dualsound.enable = true;
	modules.vm = {
		enable = getByHost false true;
		gpuPassthrough.enable = true;
	};
	modules.gaming.enable = getByHost false true;
	modules.cpuperf.enable = getByHost false true;
	modules.nixscripts = {
		enable = true;
		host.name = host.name;
	};
	programs = {
		git = {
			enable = true;
			config = {
				user.name = "Ivan Lifanov";
				user.email = "letalbark@gmail.com";
				init.defaultBranch = "main";
				core.quotepath = false;
			};
		};
		ssh.startAgent = true;
		kdeconnect.enable = true;
		steam = {
			enable = getByHost false true;
			remotePlay.openFirewall = true;
			localNetworkGameTransfers.openFirewall = true;
		};
	};
	environment.variables = let
		xdg-cache-home = "$HOME/.cache";
		xdg-config-home = "$HOME/.config";
		xdg-data-home = "$HOME/.local/share";
		xdg-state-home = "$HOME/.local/state";
	in {
		XDG_CACHE_HOME  = xdg-cache-home;
		XDG_CONFIG_HOME = xdg-config-home;
		XDG_DATA_HOME   = xdg-data-home;
		XDG_STATE_HOME  = xdg-state-home;
		PATH = [
			"$HOME/.local/bin"
		];
		HISTFILE = "${xdg-state-home}/bash/history";
		CUDA_CACHE_PATH = "${xdg-cache-home}/nv";
		CARGO_HOME = "${xdg-data-home}/cargo";
		GOPATH = "${xdg-data-home}/go";
		NPM_CONFIG_INIT_MODULE = "${xdg-config-home}/npm/config/npm-init.js";
		NPM_CONFIG_CACHE = "${xdg-cache-home}/npm";
		NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
	};

	environment.systemPackages = with pkgs; [
		eza
		obsidian
		libreoffice-qt6-still
		pavucontrol
		brave
		qbittorrent
		mpv
		tealdeer
		unzip
		lazygit
		btop
		gcc
		kdePackages.dolphin
		wl-clipboard
		xclip
		adwaita-icon-theme
		python3Minimal
		myPkgs.gitsshsetup
	] ++ getByHost [
		moonlight-qt
	] [
		mangohud
		protonup-qt
		godot
		rpcs3
		myPkgs.chlayout
	];
	fonts.packages = with pkgs; [
		noto-fonts
		noto-fonts-emoji
		nerd-fonts.jetbrains-mono
	];

	services.udev.extraRules = getByHost ''
SUBSYSTEM=="backlight", ACTION=="add", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
	'' '''';

	security.sudo.enable = false;
	security.sudo-rs.enable = true;

	system.stateVersion = "24.11"; # Did you read the comment?
}


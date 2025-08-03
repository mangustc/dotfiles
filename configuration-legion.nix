{ config, lib, pkgs, ... }:
let
	hostname = "legion";
	username = "ivan";
in
{
	nix = {
		settings = {
			experimental-features = ["nix-command" "flakes"];
			auto-optimise-store = true;
		};
	};
	nixpkgs.config.allowUnfree = true;
	nixpkgs.overlays = [
		(import ./overlays { inherit pkgs lib; })
	];

	imports = [
		./hardware-configuration-${hostname}.nix
		./modules
	];

	# SYSTEM SETTINGS
	boot = {
		loader.systemd-boot.enable = true;
		loader.efi.canTouchEfiVariables = true;
		kernelPackages = pkgs.linuxPackages_latest;
		blacklistedKernelModules = [
			"pcspkr"
			"iTCO_wdt"
			"sp5100_tco"
		];
		kernelParams = [
			"nowatchdog"
			"fbcon=vc:2-6"
			"amdgpu.sg_display=0"
		];
		initrd.kernelModules = [
			"amdgpu"
		];
		extraModulePackages = [
			config.boot.kernelPackages.acpi_call
		];
		kernelModules = [
			"acpi_call"
		];
		kernel.sysctl = {
			"net.ipv4.tcp_mtu_probing" = true;
			"net.ipv4.tcp_fin_timeout" = 5;
			"kernel.split_lock_mitigate" = 0;
			"kernel.nmi_watchdog" = 0;
			"kernel.soft_watchdog" = 0;
			"kernel.watchdog" = 0;
			"kernel.sched_cfs_bandwidth_slice_u" = 3000;
			"kernel.sched_latency_ns" = 3000000;
			"kernel.sched_min_granularity_ns" = 300000;
			"kernel.sched_wakeup_granularity_ns" = 500000;
			"kernel.sched_migration_cost_ns" = 50000;
			"kernel.sched_nr_migrate" = 128;
			"vm.max_map_count" = 2147483642;
		};
	};
	time.timeZone = "Asia/Tomsk";
	i18n.defaultLocale = "en_US.UTF-8";
	console.keyMap = "dvorak";
	hardware.graphics = {
		enable = true;
		enable32Bit = true;
	};
	zramSwap = {
		enable = true;
		algorithm = "zstd";
		memoryPercent = 50;
		priority = 100;
	};
	networking = {
		networkmanager.enable = true;
		hostName = "nixos";
	};
	modules.nethandler = {
		enable = true;
		user = "${username}";
	};
	services.pipewire = {
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

	# DESKTOP MANAGERS
	modules.hyprland.enable = false;
	modules.gnome.enable = false;
	modules.plasma.enable = true;
	services.displayManager.sddm = {
		enable = true;
		wayland.enable = true;
	};
	services.xserver = {
		enable = true;
		xkb = {
			layout = "us,ru";
			variant = "dvorak,";
			options = "grp:caps_toggle,terminate:ctrl_alt_bksp";
		};
		videoDrivers = [ "amdgpu" ];
		displayManager.lightdm.enable = lib.mkForce false;
	};

	# PROGRAMS
	modules.kitty.enable = true;
	modules.dualsound.enable = true;
	modules.neovim.enable = true;
	modules.firefox.enable = true;
	modules.fish.enable = true;
	programs.git = {
		enable = true;
		config = {
			user.name = "Ivan Lifanov";
			user.email = "letalbark@gmail.com";
			init.defaultBranch = "main";
			core.quotepath = false;
		};
	};
	modules.nixscripts = {
		enable = true;
		host.name = "${hostname}";
	};
	programs.ssh.startAgent = true;
	modules.flatpak = {
		enable = true;
		desiredFlatpaks = [
			"com.discordapp.Discord"
		];
	};
	modules.distrobox.enable = true;

	# HANDHELD USE SETTINGS
	programs.steam = {
		enable = true;
		remotePlay.openFirewall = true;
		localNetworkGameTransfers.openFirewall = true;
	};
	services.handheld-daemon = {
		enable = true;
		user = "${username}";
		ui.enable = true;
	};
	# any power profile daemons conflict with handheld-daemon
	services.power-profiles-daemon.enable = false;
	modules.steamSession.enable = true;
	programs.fuse.userAllowOther = true;
	# allow user to login in sddm without a password so you can enter with only touchpad
	security.pam.services.sddm = {
		text = lib.mkForce ''
auth      sufficient    pam_succeed_if.so user = ${username}
auth      substack      login
account   include       login
password  substack      login
session   include       login
		'';
	};
	services.udev.extraRules = ''
SUBSYSTEM=="backlight", ACTION=="add", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
	'';

	users.defaultUserShell = pkgs.bash;
	users.users.${username} = {
		isNormalUser = true;
		extraGroups = [
			"wheel"
			"audio"
			"video"
			"input"
			"tty"
			"networkmanager"
		];
		useDefaultShell = true;
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
		wl-clipboard
		xclip
		adwaita-icon-theme
		gitsshsetup
		chlayout
		python3

		# gaming
		ryubing
		rpcs3
		protonplus
		mangohud
		wineWowPackages.stable

		# development
		android-studio
	];
	fonts.packages = with pkgs; [
		noto-fonts
		noto-fonts-emoji
		nerd-fonts.jetbrains-mono
	];
	programs.nix-ld = {
		enable = true;
		# libraries = (pkgs.steam-run.fhsenv.args.multiPkgs pkgs) ++ [
		# 	pkgs.xorg.libxkbfile
		# ];
	};

	security.sudo.enable = false;
	security.sudo-rs.enable = true;

	system.stateVersion = "25.05"; # Did you read the comment?
}


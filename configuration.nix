{ config, lib, pkgs, host, ... }:

let
	mh = "main";
	gh = "gaming";
	getByHost = first: second:
		if host.name == mh then first
		else if host.name == gh then second
		else throw "Unsupported host: ${host.name}";
	gitsshsetup = import ./scripts/gitsshsetup.nix pkgs;
	chlayout = import ./scripts/chlayout.nix pkgs;
	cpuperf = import ./scripts/cpuperf.nix pkgs;
	game-performance = import ./scripts/game-performance.nix pkgs;
	virt = import ./scripts/virt.nix pkgs;
	nixupd = pkgs.writeShellScriptBin "nixupd" ''
set -e
if_root_chown() {
	if [ "$(stat -c "%U" "$1")" == "root" ]; then
		sudo chown ivan "$dotsdir/flake.lock"
	fi
}

dotsdir="$HOME/dotfiles"
if [ ! -d "$dotsdir" ]; then
	echo "can't find dotfiles in directory $dotsdir"
	return 1
fi

# optional update
if [ "$1" == "upgrade" ]; then
	nix flake update --flake "$dotsdir"
fi

# Prepare
if [ -f "$dotsdir/flake.lock" ]; then
	if_root_chown "$dotsdir/flake.lock"
	cp -v "$dotsdir/flake.lock" "$dotsdir/flake.lock.${host.name}"
fi
if [ -d "$dotsdir/.git.no" ]; then
	mv -v "$dotsdir/.git.no" "$dotsdir/.git"
fi

# Building
if [ -f "$dotsdir/flake.lock.${host.name}" ]; then
	if_root_chown "$dotsdir/flake.lock.${host.name}"
	cp -v "$dotsdir/flake.lock.${host.name}" "$dotsdir/flake.lock"
fi
if [ -d "$dotsdir/.git" ]; then
	mv -v "$dotsdir/.git" "$dotsdir/.git.no"
fi
sudo nixos-rebuild --flake "$dotsdir/#${host.name}" switch

# After build
if [ -f "$dotsdir/flake.lock" ]; then
	if_root_chown "$dotsdir/flake.lock"
	cp -vf "$dotsdir/flake.lock" "$dotsdir/flake.lock.${host.name}"
fi
if [ -d "$dotsdir/.git.no" ]; then
	mv -v "$dotsdir/.git.no" "$dotsdir/.git"
fi
	'';
	killsteamgame = pkgs.writeShellScriptBin "killsteamgame" ''
${pkgs.killall}/bin/killall GameThread
	'';
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
		./modules/boot.nix
		./modules/neovim.nix
		./modules/networking.nix
		./modules/firefox.nix
		./modules/fish.nix
		./modules/hyprland.nix
		./modules/flatpak.nix
		./modules/kitty.nix
		./modules/dualsound.nix
	];

	modules.boot = {
		enable = true;
		secureBoot.enable = getByHost true false;
	};
	boot = lib.mkIf (host.name == "gaming") {
		kernelPackages = pkgs.linuxPackages_6_14;
		kernelParams = [
			"intel_iommu=on"
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
			"kvm"
			"libvirtd"
		];
		useDefaultShell = true;
	};

	modules.neovim.enable = true;
	modules.firefox.enable = true;
	modules.fish.enable = true;
	modules.hyprland.enable = getByHost true false;
	modules.kitty.enable = true;
	modules.dualsound.enable = true;
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
		# XAUTHORITY = "$XDG_RUNTIME_DIR/Xauthority";
		VIRT_BASE_DOMAIN = "win-passthrough";
		VIRT_USB_DEVICES = "$HOME/virt/usb.json";
		LIBVIRT_DEFAULT_URI = "qemu:///system";
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
		killsteamgame
		nixupd
	] ++ getByHost [
		moonlight-qt
	] [
		mangohud
		protonup-qt
		godot
		rpcs3
	] ++ getByHost (
		[]
		++ gitsshsetup
	) (
		[]
		++ gitsshsetup
		++ chlayout
		++ cpuperf
		++ game-performance
		++ virt
	);
	fonts.packages = with pkgs; [
		noto-fonts
		noto-fonts-emoji
		nerd-fonts.jetbrains-mono
	];

	systemd.services.libvirtd = {
		preStart = ''
rm -rf /var/lib/libvirt/hooks
mkdir -p /var/lib/libvirt/hooks
mkdir -p /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin
mkdir -p /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end

echo '#!/run/current-system/sw/bin/bash

GUEST_NAME="$1"
HOOK_NAME="$2"
STATE_NAME="$3"

BASEDIR="$(dirname $0)"

if [ "$(echo "$GUEST_NAME" | grep "tmp-")" ]; then
	GUEST_NAME="$(echo "$GUEST_NAME" | sed "s|tmp-||")"
fi
HOOKPATH="$BASEDIR/qemu.d/$GUEST_NAME/$HOOK_NAME/$STATE_NAME"
set -e # If a script exits with an error, we should as well.

if [ -f "$HOOKPATH" ]; then
	eval \""$HOOKPATH"\" "$@"
elif [ -d "$HOOKPATH" ]; then
	while read file; do
		eval \""$file"\" "$@"
	done <<< "$(find -L "$HOOKPATH" -maxdepth 1 -type f -executable -print;)"
fi
' > /var/lib/libvirt/hooks/qemu
echo '#!/run/current-system/sw/bin/bash
set -x

echo efi-framebuffer.0 > /sys/bus/platform/drivers/efi-framebuffer/unbind
modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia snd_hda_intel

systemctl set-property --runtime -- system.slice AllowedCPUs=5
systemctl set-property --runtime -- user.slice AllowedCPUs=5
systemctl set-property --runtime -- init.scope AllowedCPUs=5
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
' > /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin/start.sh
echo '#!/run/current-system/sw/bin/bash
set -x

systemctl set-property --runtime -- system.slice AllowedCPUs=0-5
systemctl set-property --runtime -- user.slice AllowedCPUs=0-5
systemctl set-property --runtime -- init.scope AllowedCPUs=0-5
echo powersave | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
echo balance_performance | tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference

echo "efi-framebuffer.0" > /sys/bus/platform/drivers/efi-framebuffer/bind
modprobe nvidia_drm
modprobe nvidia_modeset
modprobe nvidia_uvm
modprobe nvidia
modprobe snd_hda_intel
' > /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end/stop.sh

chmod +x /var/lib/libvirt/hooks/qemu
chmod +x /var/lib/libvirt/hooks/qemu.d/win-passthrough/prepare/begin/start.sh
chmod +x /var/lib/libvirt/hooks/qemu.d/win-passthrough/release/end/stop.sh
		'';
	};
	virtualisation.libvirtd = {
		enable = getByHost false true;
		qemu = {
			package = pkgs.qemu_kvm;
			ovmf = {
				enable = true;
				packages = [ pkgs.OVMFFull.fd ];
			};
		};
		onBoot = "ignore";
		onShutdown = "shutdown";
	};
	programs.virt-manager.enable = getByHost false true;
	services.spice-vdagentd.enable = getByHost false true;

	services.udev.extraRules = getByHost ''
SUBSYSTEM=="backlight", ACTION=="add", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
	'' ''
SUBSYSTEM=="cpu", ACTION=="add", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/system/cpu/%k/cpufreq/scaling_governor", \
	RUN+="${pkgs.coreutils}/bin/chgrp video /sys/devices/system/cpu/%k/cpufreq/energy_performance_preference", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/devices/system/cpu/%k/cpufreq/scaling_governor", \
	RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/devices/system/cpu/%k/cpufreq/energy_performance_preference"

# Disable DS4 touchpad acting as mouse
# USB
ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
# Bluetooth
ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"

# USB
ATTRS{name}=="Sony Interactive Entertainment DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
# Bluetooth
ATTRS{name}=="DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
	'';

	security.polkit.extraConfig = ''
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (action.lookup("unit") == "nethandler.service") &&
        subject.user == "ivan") {
      return polkit.Result.YES;
    }
  });
  polkit.addRule(function(action, subject) {
    if (action.id == "org.freedesktop.systemd1.manage-units" &&
        (action.lookup("unit") == "scx.service") &&
        subject.user == "ivan") {
      return polkit.Result.YES;
    }
  });
'';
	security.sudo.enable = false;
	security.sudo-rs.enable = true;
	services.scx = {
		enable = getByHost false true;
		scheduler = "scx_lavd";
		extraArgs = [ "--performance" ];

	};
	systemd.services.scx.wantedBy = lib.mkForce [];

	system.stateVersion = "24.11"; # Did you read the comment?
}


{ config, lib, pkgs, ... }:

{
	nix.settings.experimental-features = [ "nix-command" "flakes" ];
	nixpkgs.config.allowUnfree = true;

	imports =
	[
		./hardware-configuration.nix
	];

	boot = {
		loader.systemd-boot.enable = true;
		loader.efi.canTouchEfiVariables = true;
		kernelPackages = pkgs.linuxPackages_latest;
		blacklistedKernelModules = [ "nouveau" "iTCO_wdt" "i915" ];
		kernelModules = [ "nvidia" "nvidia_drm" "nvidia_uvm" "nvidia_modeset" ];
		kernelParams = [
			"intel_iommu=on"
			"nvidia_drm.modeset=1"
			"nvidia_drm.fbdev=1"
			"nouveau.modeset=0"
			"i915.modeset=0"
			"nvidia.NVreg_UsePageAttributeTable=1"
			"nvidia.NVreg_EnablePCIeGen3=1"
			"nvidia.NVreg_DynamicPowerManagement=0"
		];
	};


	networking.firewall.enable = false;
	networking.nftables = {
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
	networking.hostName = "nixos";
	time.timeZone = "Asia/Tomsk";

	# Select internationalisation properties.
	i18n.defaultLocale = "en_US.UTF-8";
	console.keyMap = "dvorak";

	hardware.graphics.enable = true;
	hardware.nvidia = {
		# modesetting.enable = true;

		# Nvidia power management. Experimental, and can cause sleep/suspend to fail.
		# Enable this if you have graphical corruption issues or application crashes after waking
		# up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
		# of just the bare essentials.
		powerManagement.enable = false;

		powerManagement.finegrained = false;
		open = false;

		nvidiaSettings = true;

		package = config.boot.kernelPackages.nvidiaPackages.stable;
	};

	services.xserver = {
		enable = true;
		autorun = false;
		xkb = {
			layout = "us,ru";
			variant = "dvorak,";
			options = "grp:caps_toggle,terminate:ctrl_alt_bksp";
		};
		videoDrivers = ["nvidia"];
		displayManager.lightdm.enable = lib.mkForce false;
	};

	services.desktopManager = {
		plasma6.enable = true;
	};

	services.pipewire = {
		enable = true;
		pulse.enable = true;
	};

	users.defaultUserShell = pkgs.bash;
	users.users.ivan = {
		isNormalUser = true;
		extraGroups = [ "wheel" "audio" "video" "input" "tty" "kvm" "libvirtd" ];
		useDefaultShell = true;
	};

	programs = {
		firefox.enable = true;
		steam.enable = true;
	};

	environment.systemPackages = with pkgs; [
		vim
		git
		fish
		kitty
		neovim
		eza
		vesktop
		obsidian
		libreoffice-qt6-still
		lutris
		protonup-qt
		pavucontrol
		brave
		qbittorrent
		prismlauncher
		mpv
		go
		nvimpager
		jq
		pciutils
		tealdeer
		# libcap
		# zlib
		# libnetfilter_queue
		# libnfnetlink
		# gnumake
		# gcc
		discord
	];
	fonts.packages = with pkgs; [
		noto-fonts
		noto-fonts-emoji
		nerd-fonts.jetbrains-mono
	];

	systemd.services.libvirtd = {
		preStart = ''
mkdir -p /var/lib/libvirt/hooks
mkdir -p /var/lib/libvirt/hooks/qemu.d/win10/prepare/begin
mkdir -p /var/lib/libvirt/hooks/qemu.d/win10/release/end

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
' > /var/lib/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh
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
' > /var/lib/libvirt/hooks/qemu.d/win10/release/end/stop.sh

chmod +x /var/lib/libvirt/hooks/qemu
chmod +x /var/lib/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh
chmod +x /var/lib/libvirt/hooks/qemu.d/win10/release/end/stop.sh
		'';
	};
	virtualisation.libvirtd = {
		enable = true;
		qemu = {
			package = pkgs.qemu_kvm;
			verbatimConfig = ''
namespace = []
user = "1000"
group = "1000"
			'';
			ovmf = {
				enable = true;
				# packages = [ pkgs.OVMFFull.fd ];
				packages = [(pkgs.OVMF.override {
        secureBoot = true;
        tpmSupport = true;
      }).fd];
			};
		};
		onBoot = "ignore";
		onShutdown = "shutdown";
	};
	programs.virt-manager.enable = true;

	systemd.services.nethandler = {
		enable = true;
		description = "Nethandler";
		wantedBy = [ "default.target" ];
		serviceConfig = {
			ExecStart = pkgs.writeShellScript "nethandler" (builtins.readFile ./nethandler);
		};
	};

	# system.copySystemConfiguration = true;
	system.stateVersion = "24.11"; # Did you read the comment?
}


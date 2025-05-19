{ config, lib, pkgs, host, ... }:

let
	getByHost = first: second:
		if host.name == "main" then first
		else if host.name == "gaming" then second
		else throw "Unsupported host: ${host.name}";
	wm = (import ./scripts/wm.nix pkgs).pkg;
	gitsshsetup = (import ./scripts/gitsshsetup.nix pkgs).pkg;
	chlayout = (import ./scripts/chlayout.nix pkgs).pkg;
	cpuperf = (import ./scripts/cpuperf.nix pkgs).pkg;
	game-performance = (import ./scripts/game-performance.nix pkgs).pkg;
	virt = (import ./scripts/virt.nix pkgs).pkg;
	desiredFlatpaks = [
		"app.zen_browser.zen"
		"com.discordapp.Discord"
	] ++ getByHost [
	] [
	];
	flatpak-update = pkgs.writeShellScriptBin "flatpak-update" ''
echo "Adding flathub repo if not exists"
${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
installedFlatpaks=$(${pkgs.flatpak}/bin/flatpak list --app --columns=application)

for installed in $installedFlatpaks; do
	if ! echo ${toString desiredFlatpaks} | ${pkgs.gnugrep}/bin/grep -q $installed; then
		echo "Removing $installed"
		${pkgs.flatpak}/bin/flatpak uninstall -y --noninteractive $installed
	fi
done

for app in ${toString desiredFlatpaks}; do
	echo "Installing $app"
	${pkgs.flatpak}/bin/flatpak install -y flathub $app
done

echo "Removing unused apps and updating"
${pkgs.flatpak}/bin/flatpak uninstall --unused -y
${pkgs.flatpak}/bin/flatpak update -y
	'';
in {
	nix = {
		settings = {
			experimental-features = ["nix-command" "flakes"];
			auto-optimise-store = true;
		};
		gc = {
			automatic = true;
			dates = "weekly";
			options = "--delete-older-than 7d";
		};
	};
	nixpkgs.config.allowUnfree = true;

	imports =
	[
		./hardware-configuration-${host.name}.nix
	];

	boot = getByHost {
		loader.systemd-boot.enable = lib.mkForce false;
		loader.efi.canTouchEfiVariables = true;
		kernelPackages = pkgs.linuxPackages_latest;
		lanzaboote = {
			enable = getByHost true false;
			pkiBundle = "/var/lib/sbctl";
		};
		blacklistedKernelModules = [
			"pcspkr"
		];
		kernelModules = [
			"amdgpu"
		];
		kernelParams =[
			"nowatchodg"
		];
	} {
		loader.systemd-boot.enable = true;
		loader.efi.canTouchEfiVariables = true;
		kernelPackages = pkgs.linuxPackages_latest;
		blacklistedKernelModules = [
			"nouveau"
			"iTCO_wdt"
			"i915"
		];
		kernelModules = [
			"nvidia"
			"nvidia_drm"
			"nvidia_uvm"
			"nvidia_modeset"
		];
		kernelParams = [
			"nowatchdog"
			"intel_iommu=on"
			"nvidia_drm.modeset=1"
			"nvidia_drm.fbdev=1"
			"nouveau.modeset=0"
			"i915.modeset=0"
			"nvidia.NVreg_UsePageAttributeTable=1"
			"nvidia.NVreg_DynamicPowerManagement=0"
			"nvidia.Nvreg_PreserveVideoMemoryAllocations=1"
		];
	};

	networking = {
		wireless.iwd = {
			enable = getByHost true false;
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
			package = config.boot.kernelPackages.nvidiaPackages.latest;
		};
	};

	services = {
		xserver = {
			enable = true;
			autorun = false;
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
		pipewire = {
			enable = true;
			pulse.enable = true;
		};
		tlp.enable = getByHost true false;
	};
	environment.plasma6.excludePackages = with pkgs; [
		kdePackages.discover
		kdePackages.krdp
		kdePackages.elisa
		kdePackages.konsole
		kdePackages.khelpcenter
	];

	services.flatpak.enable = true;

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

	programs = {
		ssh.startAgent = true;
		steam.enable = getByHost false true;
		neovim = {
			enable = true;
			defaultEditor = true;
		};
		hyprland.enable = getByHost true false;
		bash = {
			interactiveShellInit = ''
if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
	shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
	exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
fi
			'';
		};
		fish = {
			enable = true;
			interactiveShellInit = ''
  set color00 26/26/26 # Base 00 - Black
  set color01 d7/5f/5f # Base 08 - Red
  set color02 af/af/00 # Base 0B - Green
  set color03 ff/af/00 # Base 0A - Yellow
  set color04 83/ad/ad # Base 0D - Blue
  set color05 d4/85/ad # Base 0E - Magenta
  set color06 85/ad/85 # Base 0C - Cyan
  set color07 da/b9/97 # Base 05 - White
  set color08 8a/8a/8a # Base 03 - Bright Black
  set color09 $color01 # Base 08 - Bright Red
  set color10 $color02 # Base 0B - Bright Green
  set color11 $color03 # Base 0A - Bright Yellow
  set color12 $color04 # Base 0D - Bright Blue
  set color13 $color05 # Base 0E - Bright Magenta
  set color14 $color06 # Base 0C - Bright Cyan
  set color15 eb/db/b2 # Base 07 - Bright White
  set color16 ff/87/00 # Base 09
  set color17 d6/5d/0e # Base 0F
  set color18 3a/3a/3a # Base 01
  set color19 4e/4e/4e # Base 02
  set color20 94/94/94 # Base 04
  set color21 d5/c4/a1 # Base 06
  set colorfg $color07 # Base 05 - White
  set colorbg $color00 # Base 00 - Black

  if test -n "$TMUX"
    # Tell tmux to pass the escape sequences through
    # (Source: http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324)
    function put_template; printf '\033Ptmux;\033\033]4;%d;rgb:%s\033\033\\\033\\' $argv; end;
    function put_template_var; printf '\033Ptmux;\033\033]%d;rgb:%s\033\033\\\033\\' $argv; end;
    function put_template_custom; printf '\033Ptmux;\033\033]%s%s\033\033\\\033\\' $argv; end;
  else if string match 'screen*' $TERM # [ "''${TERM%%[-.]*}" = "screen" ]
    # GNU screen (screen, screen-256color, screen-256color-bce)
    function put_template; printf '\033P\033]4;%d;rgb:%s\007\033\\' $argv; end;
    function put_template_var; printf '\033P\033]%d;rgb:%s\007\033\\' $argv; end;
    function put_template_custom; printf '\033P\033]%s%s\007\033\\' $argv; end;
  else if string match 'linux*' $TERM # [ "''${TERM%%-*}" = "linux" ]
    function put_template; test $argv[1] -lt 16 && printf "\e]P%x%s" $argv[1] (echo $argv[2] | sed 's/\///g'); end;
    function put_template_var; true; end;
    function put_template_custom; true; end;
  else
    function put_template; printf '\033]4;%d;rgb:%s\033\\' $argv; end;
    function put_template_var; printf '\033]%d;rgb:%s\033\\' $argv; end;
    function put_template_custom; printf '\033]%s%s\033\\' $argv; end;
  end

  # 16 color space
  put_template 0  $color00
  put_template 1  $color01
  put_template 2  $color02
  put_template 3  $color03
  put_template 4  $color04
  put_template 5  $color05
  put_template 6  $color06
  put_template 7  $color07
  put_template 8  $color08
  put_template 9  $color09
  put_template 10 $color10
  put_template 11 $color11
  put_template 12 $color12
  put_template 13 $color13
  put_template 14 $color14
  put_template 15 $color15

  # 256 color space
  put_template 16 $color16
  put_template 17 $color17
  put_template 18 $color18
  put_template 19 $color19
  put_template 20 $color20
  put_template 21 $color21

  # foreground / background / cursor color
  if test -n "$ITERM_SESSION_ID"
    # iTerm2 proprietary escape codes
    put_template_custom Pg dab997 # foreground
    put_template_custom Ph 262626 # background
    put_template_custom Pi dab997 # bold color
    put_template_custom Pj 4e4e4e # selection color
    put_template_custom Pk dab997 # selected text color
    put_template_custom Pl dab997 # cursor
    put_template_custom Pm 262626 # cursor text
  else
    put_template_var 10 $colorfg
    if [ "$BASE16_SHELL_SET_BACKGROUND" != false ]
      put_template_var 11 $colorbg
      if string match 'rxvt*' $TERM # [ "''${TERM%%-*}" = "rxvt" ]
        put_template_var 708 $colorbg # internal border (rxvt)
      end
    end
    put_template_custom 12 ";7" # cursor (reverse video)
  end

  # set syntax highlighting colors
  set -U fish_color_autosuggestion 4e4e4e
  set -U fish_color_cancel -r
  set -U fish_color_command green #white
  set -U fish_color_comment 4e4e4e
  set -U fish_color_cwd green
  set -U fish_color_cwd_root red
  set -U fish_color_end brblack #blue
  set -U fish_color_error red
  set -U fish_color_escape yellow #green
  set -U fish_color_history_current --bold
  set -U fish_color_host normal
  set -U fish_color_match --background=brblue
  set -U fish_color_normal normal
  set -U fish_color_operator blue #green
  set -U fish_color_param 949494
  set -U fish_color_quote yellow #brblack
  set -U fish_color_redirection cyan
  set -U fish_color_search_match bryellow --background=4e4e4e
  set -U fish_color_selection white --bold --background=4e4e4e
  set -U fish_color_status red
  set -U fish_color_user brgreen
  set -U fish_color_valid_path --underline
  set -U fish_pager_color_completion normal
  set -U fish_pager_color_description yellow --dim
  set -U fish_pager_color_prefix white --bold #--underline
  set -U fish_pager_color_progress brwhite --background=cyan

  # remember current theme
  set -U base16_theme gruvbox-dark-pale

  # clean up
  functions -e put_template put_template_var put_template_custom


# fish_config theme choose Catppuccin\ Mocha
set fzf_fd_opts --hidden --no-ignore --max-depth 5
set fzf_preview_dir_cmd eza --time-style relative -lA

function fish_greeting
    printf "\e[31m●\e[0m \e[33m●\e[0m \e[32m●\e[0m \e[36m●\e[0m \e[34m●\e[0m \e[35m●\e[0m \n"
end

function fish_prompt
    set -l nix_shell_info (
      if test -n "$IN_NIX_SHELL"
        echo -n "<nix-shell> "
      end
    )
    set -l last_pipestatus $pipestatus
    set -lx __fish_last_status $status # Export for __fish_print_pipestatus.
    set -l normal (set_color normal)
    set -q fish_color_status
    or set -g fish_color_status red

    # Color the prompt differently when we're root
    set -l color_cwd $fish_color_cwd
    set -l suffix '>'
    if functions -q fish_is_root_user; and fish_is_root_user
        if set -q fish_color_cwd_root
            set color_cwd $fish_color_cwd_root
        end
        set suffix '#'
    end

    # Write pipestatus
    # If the status was carried over (if no command is issued or if `set` leaves the status untouched), don't bold it.
    set -l bold_flag --bold
    set -q __fish_prompt_status_generation; or set -g __fish_prompt_status_generation $status_generation
    if test $__fish_prompt_status_generation = $status_generation
        set bold_flag
    end
    set __fish_prompt_status_generation $status_generation
    set -l status_color (set_color $fish_color_status)
    set -l statusb_color (set_color $bold_flag $fish_color_status)
    set -l prompt_status (__fish_print_pipestatus "[" "]" "|" "$status_color" "$statusb_color" $last_pipestatus)

    echo -n -s "$nix_shell_info" (set_color $color_cwd) (prompt_pwd -D 3) $normal (fish_vcs_prompt) $normal " "$prompt_status $suffix " "
end

function nixupd
    set dotsdir "$HOME/dotfiles"
    if not test -d "$dotsdir"
        echo "can't find dotfiles in directory $dotsdir"
        return 1
    end
    if test -d "$dotsdir/.git.no"
        mv "$dotsdir/.git.no" "$dotsdir/.git"
    end
    if test -d "$dotsdir/.git"
        mv "$dotsdir/.git" "$dotsdir/.git.no"
    end
    sudo nixos-rebuild --flake $dotsdir/#${host.name} switch $argv
    if test -d "$dotsdir/.git.no"
        mv "$dotsdir/.git.no" "$dotsdir/.git"
    end
end

function nix-index
	sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
	sudo nix-channel --update
end

function nix-clean
	nix-collect-garbage --delete-old
	sudo nix-collect-garbage -d
	sudo /run/current-system/bin/switch-to-configuration boot
end

function nix-edit
	nvim "$(whereis $argv | cut -d " " -f 2)"
end
alias eza "eza -M --icons=always --no-permissions --group-directories-first --git --color=always"
abbr --position anywhere nix-shell "nix-shell --run 'fish'";
abbr --position anywhere rm "rm -vrf";
abbr --position anywhere cp "cp -vr";
abbr --position anywhere mv "mv -vf";
abbr --position anywhere t "tldr";
abbr --position anywhere tree "tree -C";
abbr --position anywhere ls "eza --time-style relative -lA";
abbr --position anywhere lst "eza --time-style relative -lA -T";
abbr --position anywhere lss "eza --time-style relative -lA --total-size";
abbr --position anywhere lsst "eza --time-style relative -lA -T --total-size";
abbr --position anywhere lsts "eza --time-style relative -lA -T --total-size";
abbr --position anywhere pgenx "pgen | xclip -sel clip";
abbr --position anywhere pgenw "pgen | wl-copy";

			'';
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
		WM_NAME = getByHost "hyprland" "kde";
		WM_ARGS = getByHost "" "wayland";
		HISTFILE = "${xdg-state-home}/bash/history";
		CUDA_CACHE_PATH = "${xdg-cache-home}/nv";
		CARGO_HOME = "${xdg-data-home}/cargo";
		GOPATH = "${xdg-data-home}/go";
		NPM_CONFIG_INIT_MODULE = "${xdg-config-home}/npm/config/npm-init.js";
		NPM_CONFIG_CACHE = "${xdg-cache-home}/npm";
		NPM_CONFIG_TMP = "$XDG_RUNTIME_DIR/npm";
		XAUTHORITY = "$XDG_RUNTIME_DIR/Xauthority";
	} // getByHost {
	} {
		VIRT_BASE_DOMAIN = "win-passthrough";
		VIRT_USB_DEVICES = "$HOME/virt/usb.json";
		LIBVIRT_DEFAULT_URI = "qemu:///system";
	};

	environment.systemPackages = with pkgs; [
		git
		kitty
		eza
		obsidian
		libreoffice-qt6-still
		pavucontrol
		brave
		qbittorrent
		mpv
		tealdeer
		unzip
		nil
		python313Packages.python-lsp-server
		lua-language-server
		lazygit
		btop
		wl-clipboard
		gcc
		kdePackages.dolphin
		libnetfilter_queue
		adwaita-icon-theme
		flatpak-update
	] ++ getByHost [
		sbctl
	] [
		mangohud
		protonup-qt
	] ++ getByHost (
		[]
		++ wm
		++ gitsshsetup
	) (
		[]
		++ wm
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
	programs.virt-manager.enable = getByHost false true;

	systemd.services.nethandler = {
		enable = true;
		description = "Nethandler";
		wantedBy = [ "default.target" ];
		serviceConfig = {
			ExecStart = pkgs.writeShellScript "nethandler" (builtins.readFile ./nethandler);
		};
	};

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


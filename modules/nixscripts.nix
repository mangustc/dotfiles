{ config, lib, pkgs, ... }:

let
	cfg = config.modules.nixscripts;
in {
	options.modules.nixscripts = {
		enable = lib.mkEnableOption "Enable flatpak";
		dotfilesPath = lib.mkOption {
			default = "$HOME/dotfiles";
			description = "dotfiles dir";
			type = lib.types.str;
		};
		host.name = lib.mkOption {
			default = "unknown";
			description = "host name";
			type = lib.types.str;
		};
	};

	config = lib.mkIf cfg.enable {
		environment.systemPackages = with pkgs; [
			(
				pkgs.writeShellScriptBin "nixupd" ''
set -e
if_root_chown() {
	if [ "$(stat -c "%U" "$1")" == "root" ]; then
		sudo chown ivan "$dotsdir/flake.lock"
	fi
}

dotsdir="${cfg.dotfilesPath}"
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
	cp -v "$dotsdir/flake.lock" "$dotsdir/flake.lock.${cfg.host.name}"
fi
if [ -d "$dotsdir/.git.no" ]; then
	mv -v "$dotsdir/.git.no" "$dotsdir/.git"
fi

# Building
if [ -f "$dotsdir/flake.lock.${cfg.host.name}" ]; then
	if_root_chown "$dotsdir/flake.lock.${cfg.host.name}"
	cp -v "$dotsdir/flake.lock.${cfg.host.name}" "$dotsdir/flake.lock"
fi
if [ -d "$dotsdir/.git" ]; then
	mv -v "$dotsdir/.git" "$dotsdir/.git.no"
fi
sudo nixos-rebuild --flake "$dotsdir/#${cfg.host.name}" switch

# After build
if [ -f "$dotsdir/flake.lock" ]; then
	if_root_chown "$dotsdir/flake.lock"
	cp -vf "$dotsdir/flake.lock" "$dotsdir/flake.lock.${cfg.host.name}"
fi
if [ -d "$dotsdir/.git.no" ]; then
	mv -v "$dotsdir/.git.no" "$dotsdir/.git"
fi
				''
			)
			(
				pkgs.writeShellScriptBin "nixconf" ''
cd ${cfg.dotfilesPath}
$EDITOR ./configuration-${cfg.host.name}.nix
				''
			)
			(
				pkgs.writeShellScriptBin "nixindex" ''
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nix-channel --update
				''
			)
			(
				pkgs.writeShellScriptBin "nixclean" ''
nix-collect-garbage --delete-old
sudo nix-collect-garbage -d
sudo /run/current-system/bin/switch-to-configuration boot
				''
			)
			(
				pkgs.writeShellScriptBin "nixedit" ''
nvim "$(whereis $1 | cut -d " " -f 2)"
				''
			)
		];
	};
}


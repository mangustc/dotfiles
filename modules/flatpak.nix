{ config, lib, pkgs, ... }:

let
	cfg = config.modules.flatpak;
	desiredFlatpaks = config.modules.flatpak.desiredFlatpaks;
in {
	options.modules.flatpak = {
		enable = lib.mkEnableOption "Enable flatpak";
		desiredFlatpaks = lib.mkOption {
			default = [];
			description = "choose flatpaks to install";
			type = lib.types.listOf lib.types.str;
		};
	};

	config = lib.mkIf cfg.enable {
		services.flatpak.enable = true;
		environment.systemPackages = with pkgs; [
			(pkgs.writeShellScriptBin "flatpak-update" ''
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
			'')
		];
	};
}


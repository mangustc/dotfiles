{ pkgs, ... }:
pkgs.stdenv.mkDerivation rec {
  pname = "chlayout";
  version = "1.0";

  # The script source
  src = pkgs.writeShellScriptBin pname ''
if [ "$1" = "default" ]; then
	if ([ ! "$KDE_SESSION_UID" == "" ] || [ "$XDG_CURRENT_DESKTOP" == "KDE" ]) && ([ ! "$WAYLAND_DISPLAY" == "" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]); then
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key LayoutList "us,ru"
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key VariantList "dvorak,"
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Options "terminate:ctrl_alt_bksp,grp:caps_toggle"
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key ResetOldOptions "true"
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Use "true"
		dbus-send --session --type=signal --dest=org.kde.keyboard /Layouts org.kde.keyboard.reloadConfig
	else
		setxkbmap -layout us,ru -variant dvorak, -option "grp:caps_toggle" -option "terminate:ctrl_alt_bksp"
	fi
elif [ "$1" = "gaming" ]; then
	if ([ ! "$KDE_SESSION_UID" == "" ] || [ "$XDG_CURRENT_DESKTOP" == "KDE" ]) && ([ ! "$WAYLAND_DISPLAY" == "" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]); then
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key LayoutList "us"
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key VariantList ""
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Options "terminate:ctrl_alt_bksp"
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key ResetOldOptions "true"
		${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Use "true"
		dbus-send --session --type=signal --dest=org.kde.keyboard /Layouts org.kde.keyboard.reloadConfig
	else
		setxkbmap -layout us -option "terminate:ctrl_alt_bksp"
	fi
else
	echo "Unknown option: \"$1\""
fi
  '';

  # buildInputs = [ pkgs.kdePackages.kconfig ];
  # dontWrapQtApps = true;
# nativeBuildInputs = [ pkgs.wrapQtAppsNoGuiHook ];
# buildInputs = [ pkgs.qtbase ];

  # Install the script to $out/bin
  installPhase = ''
    mkdir -p $out/bin
    cp ${src}/bin/${pname} $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';

  meta = with pkgs.lib; {
    description = "Keyboard layout switching script for KDE and X11";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
  };
}


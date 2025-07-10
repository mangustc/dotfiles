{ prev, final, lib, ... }:
let
	pkgs = prev;
in
pkgs.stdenv.mkDerivation rec {
  pname = "chlayout";
  version = "1.0";
  src = pkgs.writeShellScriptBin pname ''
export PATH="${pkgs.kdePackages.kconfig}/bin:$PATH"
if [ "$1" = "default" ]; then
	if ([ ! "$KDE_SESSION_UID" == "" ] || [ "$XDG_CURRENT_DESKTOP" == "KDE" ]) && ([ ! "$WAYLAND_DISPLAY" == "" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]); then
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key LayoutList "us,ru"
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key VariantList "dvorak,"
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Options "terminate:ctrl_alt_bksp,grp:caps_toggle"
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key ResetOldOptions "true"
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Use "true"
		dbus-send --session --type=signal --dest=org.kde.keyboard /Layouts org.kde.keyboard.reloadConfig
	else
		setxkbmap -layout us,ru -variant dvorak, -option "grp:caps_toggle" -option "terminate:ctrl_alt_bksp"
	fi
elif [ "$1" = "gaming" ]; then
	if ([ ! "$KDE_SESSION_UID" == "" ] || [ "$XDG_CURRENT_DESKTOP" == "KDE" ]) && ([ ! "$WAYLAND_DISPLAY" == "" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]); then
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key LayoutList "us"
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key VariantList ""
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Options "terminate:ctrl_alt_bksp"
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key ResetOldOptions "true"
		kwriteconfig6 --file ~/.config/kxkbrc --group Layout --key Use "true"
		dbus-send --session --type=signal --dest=org.kde.keyboard /Layouts org.kde.keyboard.reloadConfig
	else
		setxkbmap -layout us -option "terminate:ctrl_alt_bksp"
	fi
else
	echo "Unknown option: \"$1\""
fi
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${src}/bin/${pname} $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';
}


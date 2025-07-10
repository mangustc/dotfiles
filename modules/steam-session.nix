{ config, lib, pkgs, ... }:

let
	cfg = config.modules.steamSession;
	steamCfg = config.programs.steam;
	steam-gamescope =
	let
		exports = builtins.attrValues (
			builtins.mapAttrs (n: v: "export ${n}=${v}") steamCfg.gamescopeSession.env
		);
	in
	pkgs.writeShellScriptBin "steam-gamescope" ''
exec 1> >(logger -t $0) && exec 2> >(logger -p err -t $0) && exec 5> >(logger -p debug -t $0) && BASH_XTRACEFD="5" PS4='$LINENO: '

tmpdir="$([[ -n ${"$"}{XDG_RUNTIME_DIR+x} ]] && mktemp -p "/tmp" -d -t gamescope.XXXXXXX)"
# socket="${"$"}{tmpdir:+$tmpdir/startup.socket}"
# stats="${"$"}{tmpdir:+$tmpdir/stats.pipe}"
if [[ -z $tmpdir ]]; then
	echo >&2 "!! Failed to find run directory in which to create stats session sockets (is \$XDG_RUNTIME_DIR set?)"
	exit 0
fi

# Mangoapp
export STEAM_MANGOAPP_PRESETS_SUPPORTED=1
export STEAM_USE_MANGOAPP=1
export STEAM_DISABLE_MANGOAPP_ATOM_WORKAROUND=1
export STEAM_MANGOAPP_HORIZONTAL_SUPPORTED=1
export MANGOHUD_CONFIGFILE="${"$"}{tmpdir:+$tmpdir/mangohud.config}"
mkdir -p "$(dirname "$MANGOHUD_CONFIGFILE")"
echo -e "no_display" > "$MANGOHUD_CONFIGFILE"

# export RADV_FORCE_VRS_CONFIG_FILE="${"$"}{tmpdir:+$tmpdir/radv_vrs.config}"
# export STEAM_USE_DYNAMIC_VRS=1
# mkdir -p "$(dirname "$RADV_FORCE_VRS_CONFIG_FILE")"
# echo "1x1" >"$RADV_FORCE_VRS_CONFIG_FILE"

export GAMESCOPE_MODE_SAVE_FILE="${"$"}{XDG_CONFIG_HOME:-$HOME/.config}/gamescope/modes.cfg"
mkdir -p "$(dirname "$GAMESCOPE_MODE_SAVE_FILE")"
touch "$GAMESCOPE_MODE_SAVE_FILE"

export GAMESCOPE_PATCHED_EDID_FILE="${"$"}{XDG_CONFIG_HOME:-$HOME/.config}/gamescope/edid.bin"
mkdir -p "$(dirname "$GAMESCOPE_PATCHED_EDID_FILE")"
touch "$GAMESCOPE_PATCHED_EDID_FILE"

export GAMESCOPE_LIMITER_FILE="${"$"}{tmpdir:+$tmpdir/gamescope-limiter}"

export SDL_VIDEO_MINIMIZE_ON_FOCUS_LOSS=0
export GAMESCOPE_NV12_COLORSPACE=k_EStreamColorspace_BT601
export INTEL_DEBUG = "norbc";
export mesa_glthread = "true";
export STEAM_GAMESCOPE_HDR_SUPPORTED=1
export VKD3D_SWAPCHAIN_LATENCY_FRAMES=3
export WINEDLLOVERRIDES=dxgi=n
export STEAM_ENABLE_DYNAMIC_BACKLIGHT=1
export STEAM_ENABLE_VOLUME_HANDLER=1
export SRT_URLOPEN_PREFER_STEAM=1
export STEAM_DISABLE_AUDIO_DEVICE_SWITCHING=1
export STEAM_MULTIPLE_XWAYLANDS=1
export STEAM_GAMESCOPE_DYNAMIC_FPSLIMITER=1
export STEAM_GAMESCOPE_HAS_TEARING_SUPPORT=1
export STEAM_GAMESCOPE_NIS_SUPPORTED=1
export STEAM_GAMESCOPE_TEARING_SUPPORTED=1
export STEAM_GAMESCOPE_VRR_SUPPORTED=1
export STEAM_GAMESCOPE_DYNAMIC_REFRESH_IN_STEAM_SUPPORTED=0
export STEAM_ENABLE_STATUS_LED_BRIGHTNESS=1
export vk_xwayland_wait_ready=false
export STEAM_ALLOW_DRIVE_UNMOUNT=0
export STEAM_ALLOW_DRIVE_ADOPT=0
export STEAM_GAMESCOPE_FANCY_SCALING_SUPPORT=1
export STEAM_GAMESCOPE_COLOR_MANAGED=1
export STEAM_GAMESCOPE_VIRTUAL_WHITE=1
export STEAM_ENABLE_CEC=1
export QT_IM_MODULE=steam
export GTK_IM_MODULE=Steam
export QT_QPA_PLATFORM = "xcb";
export QT_QPA_PLATFORM_THEME=kde
export ENABLE_GAMESCOPE_WSI=1
export GAMESCOPE_DISABLE_ASYNC_FLIPS=1
export XCURSOR_THEME=steam
export XCURSOR_SCALE=256
export STEAM_DISPLAY_REFRESH_LIMITS=60,144

kwriteconfig6 --file gtk-3.0/settings.ini  --group Settings --key gtk-cursor-theme-name steam
touch ~/.steam/root/config/SteamAppData.vdf || true

# export GAMESCOPE_STATS="$stats"
# mkfifo -- "$stats"
# mkfifo -- "$socket"
# if read -r -t 3 response_x_display response_wl_display <> "$socket"; then
# 	export DISPLAY="$response_x_display"
# 	export GAMESCOPE_WAYLAND_DISPLAY="$response_wl_display"
# fi

${builtins.concatStringsSep "\n" exports}

# (while true; do
# 	mangoapp
# 	sleep 5
# done) &
gamescope --steam \
	--mangoapp \
	--force-orientation left \
	--prefer-output '*,eDP-1' \
	--xwayland-count 2 \
	--default-touch-mode 4 \
	--hide-cursor-delay 3000 \
	--fade-out-duration 200 \
	-- steam \
		-gamepadui \
		-steamos3 \
		-steampal \
		-steamdeck
	'';

	gamescopeSessionFile = (pkgs.writeTextDir "share/wayland-sessions/steam.desktop" ''
[Desktop Entry]
Name=Steam session
Comment=A digital distribution platform
Exec=${steam-gamescope}/bin/steam-gamescope
Type=Application
	'').overrideAttrs(_: {
		passthru.providedSessions = [ "steam" ];
	});
	steamos-session-select = pkgs.writeShellScriptBin "steamos-session-select" ''
steam -shutdown
	'';
in {
	options.modules.steamSession = {
		enable = lib.mkEnableOption "Enable steam session";
	};

	config = lib.mkIf cfg.enable {
		programs.gamescope = {
			enable = true;
			capSysNice = true;
		};
		hardware.graphics.extraPackages = [ pkgs.gamescope-wsi ];
		hardware.graphics.extraPackages32 = [ pkgs.pkgsi686Linux.gamescope-wsi ];
		programs.steam = {
			enable = true;
			gamescopeSession.enable = true;
		};
		services.displayManager.sessionPackages = [
			gamescopeSessionFile
		];
		environment.systemPackages = [
			steamos-session-select
			steam-gamescope
			pkgs.mangohud
		];
	};
}


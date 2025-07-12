{ config, lib, pkgs, ... }:

let
	cfg = config.modules.dualsound;

in {
	options.modules.dualsound = {
		enable = lib.mkEnableOption "Enable dualsense sound";
	};

	config = lib.mkIf cfg.enable {
		services.udev.extraRules = ''
# Disable DS4 touchpad acting as mouse
# USB
ATTRS{name}=="Sony Interactive Entertainment Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
# Bluetooth
ATTRS{name}=="Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"

# Disable Dualsense touchpad acting as mouse
# USB
ATTRS{name}=="Sony Interactive Entertainment DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
# Bluetooth
ATTRS{name}=="DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"

# Disable Dualsense Edge touchpad acting as mouse
# USB
ATTRS{name}=="Sony Interactive Entertainment DualSense Edge Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
# Bluetooth
ATTRS{name}=="DualSense Edge Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
		'';
		services.pipewire.extraConfig.pipewire = {
			"99-dualsense-stereo" = {
				"context.modules" = [
					{
						name = "libpipewire-module-loopback";
						args = {
							"node.description" = "Stereo Dualsense loopback with Optional Haptic Feedback";
							"capture.props" = {
								"node.name" = "stereo_front_sink";
								"media.class" = "Audio/Sink";
								"audio.position" = [ "FL" "FR" ]; # Only front left and front right channels
							};
							"playback.props" = {
								"node.name" = "playback.surround_40_output";
								"audio.position" = [ "FL" "FR" "RL" "RR" ]; # Original surround 4.0 device channels
								"node.target" = "alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.analog-surround-40";
								"stream.dont-remix" = true;
								"node.passive" = true;
							};
						};
					}
				];
			};
		};
		environment.systemPackages = with pkgs; [
			(pkgs.writeShellScriptBin "dualsound" ''
dualsense_name="alsa_output.usb-Sony_Interactive_Entertainment_DualSense_Wireless_Controller-00.analog-surround-40"
if [ "$1" == "toggle" ]; then
	if [ "$(pw-link -l | xargs | grep "playback.surround_40_output:output_FL |-> $dualsense_name:playback_FL |-> $dualsense_name:playback_RL")" == "" ]; then
		${if config.services.desktopManager.plasma6.enable then "${pkgs.libnotify}/bin/notify-send 'Dualsense Haptic' 'Activated'" else ""}
		echo "activating"
		pw-link playback.surround_40_output:output_FL $dualsense_name:playback_RL
		pw-link playback.surround_40_output:output_FR $dualsense_name:playback_RR
	else
		${if config.services.desktopManager.plasma6.enable then "${pkgs.libnotify}/bin/notify-send 'Dualsense Haptic' 'Deactivated'" else ""}
		echo "deactivating"
		pw-link -d playback.surround_40_output:output_FL $dualsense_name:playback_RL
		pw-link -d playback.surround_40_output:output_FR $dualsense_name:playback_RR
	fi
elif [ "$1" == "level" ]; then
	if [ "$2" == "" ]; then
		echo "provide a level (number in range 0 to 100)"
		exit 1
	fi
	level="$2"
	${if config.services.desktopManager.plasma6.enable then ''${pkgs.libnotify}/bin/notify-send 'Dualsense Haptic' "Set level to $level%"'' else ""}
	pactl set-sink-volume $dualsense_name 100% 100% $level% $level%
else
	echo "no such command"
	exit 1
fi
			'')
		];
	};
}


{ config, lib, pkgs, ... }:

let
	cfg = config.modules.hyprland;
	waybarStyle = pkgs.writeText "style.css" ''
@define-color base00 #262626;
@define-color base01 #3a3a3a;
@define-color base02 #4e4e4e;
@define-color base03 #8a8a8a;
@define-color base04 #949494;
@define-color base05 #dab997;
@define-color base06 #d5c4a1;
@define-color base07 #ebdbb2;
@define-color base08 #d75f5f;
@define-color base09 #ff8700;
@define-color base0A #ffaf00;
@define-color base0B #afaf00;
@define-color base0C #85ad85;
@define-color base0D #83adad;
@define-color base0E #d485ad;
@define-color base0F #d65d0e;

* {
  font-family: "JetBrainsMono Nerd Font";
  font-size: 10pt;
  font-weight: bold;
  border-radius: 0px;
  transition-property: background-color;
  transition-duration: 0s;
  min-height: 0;
}
@keyframes blink_red {
  to {
    background-color: rgb(242, 143, 173);
    color: rgb(26, 24, 38);
  }
}
.warning,
.critical,
.urgent {
  animation-name: blink_red;
  animation-duration: 1s;
  animation-timing-function: linear;
  animation-iteration-count: infinite;
  animation-direction: alternate;
}
window > box {
  margin-left: 0px;
  margin-right: 0px;
  margin-top: 0px;
  background-color: @base00;
}
#workspaces {
  padding-left: 0px;
  padding-right: 4px;
}
#workspaces button {
  padding-top: 0px;
  padding-bottom: 0px;
  padding-left: 6px;
  padding-right: 6px;
  color: @base05;
}
#workspaces button.active {
  background-color: @base05;
  color: @base00;
}
#workspaces button.urgent {
  color: @base08;
}
#workspaces button:hover {
  background-color: @base01;
  color: @base00;
}
#mode,
#clock,
#temperature,
#cpu,
#custom-wall,
#temperature,
#backlight,
#wireplumber,
#network,
#battery,
#custom-powermenu {
  padding-left: 10px;
  padding-right: 10px;
}
#clock {
  color: @base06;
}
#temperature {
  color: @base0D;
}
#backlight {
  color: @base0A;
}
#wireplumber {
  color: @base0C;
}
#battery {
  color: @base0E;
}
	'';
	waybarConfig = pkgs.writeText "config" ''
{
      "layer": "top",
      "position": "top",
      "height": 20,
      "modules-left": ["custom/launcher", "hyprland/workspaces", "temperature", "custom/wall"],
      "modules-center": [
        "clock"
      ],
      "modules-right": [
        "wireplumber",
        "backlight",
        "battery",
        "tray"
      ],
      "hyprland/workspaces": {
        "format": "{name}",
        "on-click": "activate"
      },
      "idle_inhibitor": {
        "format": "{icon}",
        "format-icons": {
          "activated": "",
          "deactivated": "",
        },
        "tooltip": false
      },
      "backlight": {
        "device": "amdgpu_bl0",
        "format": "L {percent}%",
      },
      "wireplumber": {
        "scroll-step": 1,
        "format": "VOL {volume}%",
        "format-muted": "VOL {volume}% M",
        "tooltip": false
      },
      "battery": {
        "interval": 60,
        "states": {
          "warning": 20,
          "critical": 10
        },
        "format": "BAT {capacity}%",
        "tooltip": false
      },
      "clock": {
        "interval": 60,
        "format": "{:%I:%M %p  %A %b %d}",
        "tooltip": false,
      },
      "temperature": {
        "tooltip": false,
        "format": "TEMP {temperatureC}°C"
      },
}
	'';
	hyprlandConfig = pkgs.writeText "hyprland.conf" ''
monitor=HDMI-A-1,1920x1080,0x0,1
monitor=eDP-1,2240x1400,0x0,1.458333
exec-once = echo 180 > /sys/class/backlight/amdgpu_bl1/brightness
windowrulev2 = suppressevent maximize, class:.*
windowrulev2 = nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0
workspace = w[tv1], gapsout:0, gapsin:0
workspace = f[1], gapsout:0, gapsin:0
windowrulev2 = bordersize 0, floating:0, onworkspace:w[tv1]
windowrulev2 = rounding 0, floating:0, onworkspace:w[tv1]
windowrulev2 = bordersize 0, floating:0, onworkspace:f[1]
windowrulev2 = rounding 0, floating:0, onworkspace:f[1]
# windowrule = workspace 2 silent, ^(zen-browser)$
# windowrule = float, ^(pavucontrol)$
env = XCURSOR_SIZE,24
env = XCURSOR_THEME,Adwaita
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland;xcb
env = GDK_BACKEND,wayland,x11
env = SDL_VIDEODRIVER,wayland
env = CLUTTER_BACKEND,wayland
env = MOZ_ENABLE_WAYLAND,1
env = HYPRCURSOR_THEME,Adwaita
env = HYPRCURSOR_SIZE,24
$base00 = 0xff262626
$base01 = 0xff3a3a3a
$base02 = 0xff4e4e4e
$base03 = 0xff8a8a8a
$base04 = 0xff949494
$base05 = 0xffdab997
$base06 = 0xffd5c4a1
$base07 = 0xffebdbb2
$base08 = 0xffd75f5f
$base09 = 0xffff8700
$base0A = 0xffffaf00
$base0B = 0xffafaf00
$base0C = 0xff85ad85
$base0D = 0xff83adad
$base0E = 0xffd485ad
$base0F = 0xffd65d0e
general {
    gaps_in = 2
    gaps_out = 0
    border_size = 1
    col.active_border = $base05
    col.inactive_border = $base02
    resize_on_border = false
    allow_tearing = true
    layout = dwindle
}
decoration {
    rounding = 0
    active_opacity = 1.0
    inactive_opacity = 1.0
    shadow {
        enabled = false
    }
    blur {
        enabled = false
    }
}
cursor {
    hide_on_key_press = true
    no_warps = true
    inactive_timeout = 5
    enable_hyprcursor = false
    # no_hardware_cursors = false
}
input {
    kb_layout = us,ru
    kb_variant = dvorak,
    kb_model =
    kb_options = grp:caps_toggle
    kb_rules =
    follow_mouse = 1
    sensitivity = 0 # -1.0 - 1.0, 0 means no modification.
    repeat_rate = 50
    repeat_delay = 300
    touchpad {
        natural_scroll = false
        scroll_factor = 0.15
    }
}
device {
    name = compx-2.4g-wireless-receiver
    sensitivity = -0.8
    accel_profile = flat
}
animations {
    enabled = no
}
dwindle {
    pseudotile = true
    preserve_split = true
}
master {
    new_status = master
}
misc {
    force_default_wallpaper = 0
    disable_hyprland_logo = true
    background_color = $base00
}
gestures {
    workspace_swipe = false
}
ecosystem {
    no_update_news = true
    # no_donation_nag = true
}
xwayland {
    force_zero_scaling = true
}
experimental {
    xx_color_management_v4 = true
}
bind = SUPER SHIFT, D, exec, hyprctl keyword monitor eDP-1,disabled
bind = CTRL ALT, Backspace, exit,
bind = SUPER SHIFT, S, exec, sh -c 'REGION=$(${pkgs.slurp}/bin/slurp) || exit; ${pkgs.grim}/bin/grim -g "$REGION" - | ${pkgs.wl-clipboard}/bin/wl-copy && mkdir -p ${cfg.screenshotsPath} && ${pkgs.wl-clipboard}/bin/wl-paste > ${cfg.screenshotsPath}/screenshot-$(date +%F_%T).png'
bind = , Print, exec, sh -c 'REGION=$(${pkgs.slurp}/bin/slurp) || exit; ${pkgs.grim}/bin/grim -g "$REGION" - | ${pkgs.wl-clipboard}/bin/wl-copy && mkdir -p ${cfg.screenshotsPath} && ${pkgs.wl-clipboard}/bin/wl-paste > ${cfg.screenshotsPath}/screenshot-$(date +%F_%T).png'
binde = SUPER, Down, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + -1)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1
binde = SUPER SHIFT, Down, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + -5)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1
binde = SUPER SHIFT, Up, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + +5)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1
binde = SUPER, Up, exec, new_volume=$(($(wpctl get-volume @DEFAULT_AUDIO_SINK@ | awk '{print $2 * 100}' | cut -d. -f1) + +1)); [ ''${new_volume} -le 150 ] && wpctl set-volume @DEFAULT_AUDIO_SINK@ ''${new_volume}% || exit 1binde = SUPER SHIFT, Tab, movefocus, l
binde = SUPER, Tab, movefocus, r
bind = SUPER, T, exec, KITTY_ENABLE_WAYLAND=1 kitty
bind = SUPER, C, killactive,
bind = SUPER, W, exec, sh -c "[ \"$(pidof waybar)\" = \"\" ] && exec ${pkgs.waybar}/bin/waybar --config ${waybarConfig} --style ${waybarStyle} || pkill -f waybar"
bind = SUPER, V, togglefloating,
bind = SUPER, F, fullscreen,
bind = SUPER, P, exec, BEMENU_BACKEND=wayland ${pkgs.bemenu}/bin/bemenu-run -H 20 -i
binde = SUPER SHIFT, Y, exec, echo $(($(cat /sys/class/backlight/amdgpu_bl1/brightness)-15)) > /sys/class/backlight/amdgpu_bl1/brightness
binde = SUPER, Y, exec, echo $(($(cat /sys/class/backlight/amdgpu_bl1/brightness)+15)) > /sys/class/backlight/amdgpu_bl1/brightness
bind = SUPER, Left, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
bind = SUPER, Right, exec, sh -c "[ \"$(pactl list cards | grep 'HiFi' | awk -F': ' '/Active Profile/ { print $2 }')\" = 'HiFi (Mic1, Mic2, Speaker)' ] && pactl set-card-profile 49 'HiFi (Headphones, Mic1, Mic2)' || pactl set-card-profile 49 'HiFi (Mic1, Mic2, Speaker)'"
bind = SUPER, 1, workspace, 1
bind = SUPER, 2, workspace, 2
bind = SUPER, 3, workspace, 3
bind = SUPER, 4, workspace, 4
bind = SUPER, 5, workspace, 5
bind = SUPER, 6, workspace, 6
bind = SUPER, 7, workspace, 7
bind = SUPER, 8, workspace, 8
bind = SUPER, 9, workspace, 9
bind = SUPER, 0, workspace, 10
bind = SUPER SHIFT, 1, movetoworkspace, 1
bind = SUPER SHIFT, 2, movetoworkspace, 2
bind = SUPER SHIFT, 3, movetoworkspace, 3
bind = SUPER SHIFT, 4, movetoworkspace, 4
bind = SUPER SHIFT, 5, movetoworkspace, 5
bind = SUPER SHIFT, 6, movetoworkspace, 6
bind = SUPER SHIFT, 7, movetoworkspace, 7
bind = SUPER SHIFT, 8, movetoworkspace, 8
bind = SUPER SHIFT, 9, movetoworkspace, 9
bind = SUPER SHIFT, 0, movetoworkspace, 10
bind = SUPER, mouse_down, workspace, e+1
bind = SUPER, mouse_up, workspace, e-1
bindm = SUPER, mouse:272, movewindow
bindm = SUPER, mouse:273, resizewindow
	'';
	desktop = pkgs.writeText "custom-iwctl.desktop" ''
[Desktop Entry]
Name=Hyprland (System)
Exec=${config.programs.hyprland.package}/bin/Hyprland -c ${hyprlandConfig}
Type=Application
DesktopNames=hyprland-system
	'';
in {
	options.modules.hyprland = {
		enable = lib.mkEnableOption "Enable hyprland";
		screenshotsPath = lib.mkOption {
			default = "$HOME/screenshots";
			description = "path to screenshots directory";
			type = lib.types.str;
		};
	};

	config = lib.mkIf cfg.enable {
		programs.hyprland.enable = true;
		services.displayManager.sessionPackages = [
			(pkgs.stdenv.mkDerivation {
				name = "hyprland-system";
				buildCommand = ''
mkdir -p $out/share/wayland-sessions
cp ${desktop} $out/share/wayland-sessions/hyprland-system.desktop
				'';
				passthru.providedSessions = [ "hyprland-system" ];
			})
		];
		programs.dconf.enable = true;
		environment.systemPackages = with pkgs; [
			evince
			file-roller
			nautilus
			loupe
			gnome-themes-extra
		];
	};
}


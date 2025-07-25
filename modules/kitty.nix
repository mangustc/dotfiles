{ config, lib, pkgs, ... }:

let
	cfg = config.modules.kitty;
in {
	options.modules.kitty = {
		enable = lib.mkEnableOption "Enable flatpak";
	};

	config = lib.mkIf cfg.enable {
		environment.etc."xdg/kitty/kitty.conf".text = ''
font_size        13
font_family      JetBrainsMono Nerd Font
bold_font        auto
italic_font      auto
bold_italic_font auto
confirm_os_window_close 2
enable_audio_bell no
shell_integration disabled
cursor_blink_interval 0

background #262626
foreground #dab997
selection_background #dab997
selection_foreground #262626
url_color #949494
cursor #dab997
active_border_color #8a8a8a
inactive_border_color #3a3a3a
active_tab_background #262626
active_tab_foreground #dab997
inactive_tab_background #3a3a3a
inactive_tab_foreground #949494
tab_bar_background #3a3a3a
color0 #262626
color1 #d75f5f
color2 #afaf00
color3 #ffaf00
color4 #83adad
color5 #d485ad
color6 #85ad85
color7 #dab997
color8 #8a8a8a
color9 #ff8700
color10 #3a3a3a
color11 #4e4e4e
color12 #949494
color13 #d5c4a1
color14 #d65d0e
color15 #ebdbb2
		'';
		fonts.packages = with pkgs; [
			nerd-fonts.jetbrains-mono
		];
		environment.systemPackages = with pkgs; [
			kitty
		];
	};
}


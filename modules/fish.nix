{ config, lib, pkgs, ... }:

let
	cfg = config.modules.fish;
in {
	options.modules.fish = {
		enable = lib.mkEnableOption "Enable fish";
	};

	config = lib.mkIf cfg.enable {
		programs.bash = {
			interactiveShellInit = ''
if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]; then
	shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
	exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
fi
			'';
		};
		programs.fish = {
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

alias eza "eza -M --icons=always --no-permissions --group-directories-first --git --color=always"
abbr --position anywhere ns "nix-shell --run fish -p";
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
		environment.systemPackages = with pkgs; [
		];
	};
}


#!/usr/bin/env sh

usage() {
	cat <<EOF
Example: ./configuration-$DOTFILES_HOST.sh [--module|-m MODULE_NAME]
EOF
}
usage_err() {
	[ "$1" ] && echo "$1" >&2
	usage
	exit 1
}

while [ $# -gt 0 ]; do
	case $1 in
		--module|-m)
			[ "$2" = "" ] && usage_err "Argument not specified"
			export DOTFILES_SPECIFIC_MODULE="$2"
			shift
			;;
		*)
			usage_err "Invalid option: $1"
			;;
	esac
	shift
done


if [ "$(whoami)" = "root" ]; then
	echo "DO NOT RUN THIS SCRIPT AS ROOT!!!!"
	exit 1
fi

export DOTFILES_SAVE_DIR="$DOTFILES_DIR/save/$(date +%Y-%m-%d_%H-%M-%S)"
export DOTFILES_MODULE_NAME="$DOTFILES_HOST"
export DOTFILES_MODULE_PACKAGES_FILE="$DOTFILES_SAVE_DIR/pkgs"
export DOTFILES_MODULES_TEMP_DIR="$DOTFILES_SAVE_DIR/temp"
export DOTFILES_SECRETS_DIR="$DOTFILES_DIR/secrets"
mkdir -p "$DOTFILES_SAVE_DIR"
touch "$DOTFILES_MODULE_PACKAGES_FILE"

# echo as error
errcho() {
	>&2 echo $@
}
export -f errcho

# prints command to log
cmd() {
	echo "cmd ($DOTFILES_MODULE_NAME): $@" | tee -a "$DOTFILES_SAVE_DIR/log"
	"$@" 2>&1 | tee -a "$DOTFILES_SAVE_DIR/log"

	cmd_output="$("$@")"
	cmd_status="$?"
	echo "$cmd_output" | sed '${/^$/d;}' | tee -a "$DOTFILES_SAVE_DIR/log"
	return $cmd_status
}
export -f cmd

# create file with content and return temporary file path
writetext() {
	writetext_content="$1"
	writetext_tmp="$(mktemp "/tmp/writetext.XXXXXXXXXXXXX")"

	if [ "$writetext_content" = "" ]; then
		if read -t 0; then
			cat > "$writetext_tmp"
		else
			echo "$writetext_content" > "$writetext_tmp"
		fi
	elif [ ! "$2" = "" ]; then
		errcho "writetext accepts only one argument or a heredoc"
		return 1
	else
		echo "$writetext_content" > "$writetext_tmp"
	fi

	echo "$writetext_tmp"
}
export -f writetext

# create new script inside /usr/local/bin with name and content
newscript() {
	newscript_name="$1"

	if [ "$2" = "" ]; then
		newscript_content="$(cat)"
	elif [ ! "$3" = "" ]; then
		errcho "newscript accepts only two arguments: name, (content or a heredoc)"
		return 1
	else
		newscript_content="$2"
	fi

	newscript_tmp="$(writetext "$newscript_content")"
	cmd sudo install -D -m 755 "$newscript_tmp" "/usr/local/bin/$newscript_name"
}
export -f newscript

# remove empty lines from string
rm_empty() {
	echo "$1" | awk 'NF'
}
export -f rm_empty

# remove comments, remove empty lines, remove duplicate strings, sort. string or fil
trim_pkgs_str() {
	echo "$1" | sed '/^#/d' | awk 'NF' | uniq | sort
}
trim_pkgs_file() {
	trim_pkgs_str "$(cat "$1")"
}
export -f trim_pkgs_str
export -f trim_pkgs_file

# print orphan and overlapping packages. should be used at the end of configuration-HOST.sh
print_orphan_packages() {
	! [ "$DOTFILES_SPECIFIC_MODULE" = "" ] && return 0
	echo "Current orphan packages (not in modules, not in packages-$DOTFILES_HOST):"
	grep -v -F -x -f <(echo -e "$(cat ./packages-$DOTFILES_HOST)\n$(cat "$DOTFILES_MODULE_PACKAGES_FILE")") <<< "$(paru -Qe | cut -d ' ' -f 1)"
	# echo "Current overlapping packages (between packages-$DOTFILES_HOST and modules):"
	# comm -12 <(echo "$(trim_pkgs_str "$DOTFILES_MODULE_PACKAGES")") <(trim_pkgs_file ./packages-$DOTFILES_HOST)
}
export -f print_orphan_packages

# installes packages from a string of package names
install_pkgs() {
	install_pkgs_list="$(trim_pkgs_str "$1" | grep -v -F -x -f <(echo "$(paru -Q | cut -d ' ' -f 1)") || true)"
	if [ ! "$install_pkgs_list" = "" ]; then
		paru -S --needed "$install_pkgs_list"
	fi
	prev_pkgs="$(cat "$DOTFILES_MODULE_PACKAGES_FILE")"

	echo "$(trim_pkgs_str "$prev_pkgs$(echo -e "\n$(trim_pkgs_str "$1")")")" > $DOTFILES_MODULE_PACKAGES_FILE
}
export -f install_pkgs

add_module_temp() {
	module_name="$1"
	file="$2"
	temp_dir="$DOTFILES_MODULES_TEMP_DIR/$module_name/files"
	[ -d "$temp_dir" ] || mkdir -p "$temp_dir"
	cp -rf "$2" "$temp_dir"
}
export -f add_module_temp

# by module name, install a module and its packages. You can also pass arguments if possible by a module
config() {
	export DOTFILES_MODULE_NAME="$1"
	! [ "$DOTFILES_SPECIFIC_MODULE" = "" ] && ! [ "$DOTFILES_MODULE_NAME" = "$DOTFILES_SPECIFIC_MODULE" ] && return 0
	export DOTFILES_MODULE_SECRETS="$DOTFILES_SECRETS_DIR/$DOTFILES_MODULE_NAME"
	export DOTFILES_MODULE_TEMP="$DOTFILES_MODULES_TEMP_DIR/$DOTFILES_MODULE_NAME"
	[ -d "$DOTFILES_MODULE_SECRETS" ] || mkdir -p "$DOTFILES_MODULE_SECRETS"
	[ -d "$DOTFILES_MODULE_TEMP" ] || mkdir -p "$DOTFILES_MODULE_TEMP"
	echo -e "\ninstalling module $DOTFILES_MODULE_NAME:"
	cd "$DOTFILES_DIR/modules/$DOTFILES_MODULE_NAME"
	install_pkgs "$(trim_pkgs_file ./packages)"
	chmod 755 ./install
	./install "${@:2}"
	if [ $? -eq 1 ]; then
		echo -e "FAILED TO INSTALL MODULE $DOTFILES_MODULE_NAME"
	else
		echo -e "successfully installed module $DOTFILES_MODULE_NAME"
	fi
	cd "$DOTFILES_DIR"
}

trap "echo 'Interrupt signal received. Exiting...' | tee -a '$DOTFILES_SAVE_DIR/log'; exit" SIGINT


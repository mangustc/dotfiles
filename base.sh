#!/usr/bin/env sh

if [ "$(whoami)" = "root" ]; then
	echo "DO NOT RUN THIS SCRIPT AS ROOT!!!!"
	exit 1
fi

export DOTFILES_SAVE_DIR="$DOTFILES_DIR/save/$(date +%Y-%m-%d_%H-%M-%S)"
export DOTFILES_MODULE_NAME="$DOTFILES_HOST"
export DOTFILES_MODULE_PACKAGES=""
mkdir -p "$DOTFILES_SAVE_DIR"

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
	echo "Current orphan packages (not in modules, not in packages-$DOTFILES_HOST):"
	grep -v -F -x -f <(echo -e "$(cat ./packages-$DOTFILES_HOST)\n$DOTFILES_MODULE_PACKAGES") <<< "$(paru -Qe | cut -d ' ' -f 1)"
	# echo "Current overlapping packages (between packages-$DOTFILES_HOST and modules):"
	# comm -12 <(echo "$(trim_pkgs_str "$DOTFILES_MODULE_PACKAGES")") <(trim_pkgs_file ./packages-$DOTFILES_HOST)
}
export -f print_orphan_packages

# installes packages from a string of package names
install_pkgs() {
	install_pkgs_paru=""
	install_pkgs_list="$(trim_pkgs_str "$1" | grep -v -F -x -f <(echo "$(paru -Q | cut -d ' ' -f 1)"))"
	if [ ! "$install_pkgs_list" = "" ]; then
		paru -S --needed $install_pkgs_list
	fi
}
export -f install_pkgs

# by module name, install a module and its packages. You can also pass arguments if possible by a module
config() {
	export DOTFILES_MODULE_NAME="$1"
	echo -e "\ninstalling module $DOTFILES_MODULE_NAME:"
	cd "$DOTFILES_DIR/modules/$DOTFILES_MODULE_NAME"
	pkgs="$(trim_pkgs_file ./packages)"
	install_pkgs "$pkgs"
	DOTFILES_MODULE_PACKAGES="$(trim_pkgs_str "$DOTFILES_MODULE_PACKAGES$(echo -e "\n$pkgs")")"
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


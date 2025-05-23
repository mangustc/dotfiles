{ pkgs, ... }:

let
	script = pkgs.writeShellScriptBin "gitsshsetup" ''
AUTHOR="mangustc"

if [[ $# -eq 1 ]]; then
	cd $1
fi

if git rev-parse --show-toplevel; then
	REPOSITORY_NAME="$(basename "$(git rev-parse --show-toplevel)")"
else
	echo "Error: No repository at given directory"
	exit 1
fi

echo "git remote set-url origin git@github.com:$AUTHOR/$REPOSITORY_NAME.git"
git remote set-url origin git@github.com:"$AUTHOR"/"$REPOSITORY_NAME".git
	'';
in [
	script
]


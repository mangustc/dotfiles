{ pkgs, ... }:
pkgs.stdenv.mkDerivation rec {
  pname = "gitsshsetup";
  version = "1.0";
  src = pkgs.writeShellScriptBin pname ''
export PATH="${pkgs.kdePackages.kconfig}/bin:$PATH"
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

  installPhase = ''
    mkdir -p $out/bin
    cp ${src}/bin/${pname} $out/bin/${pname}
    chmod +x $out/bin/${pname}
  '';

  # meta = with pkgs.lib; {
  #   description = "Keyboard layout switching script for KDE and X11";
  #   license = licenses.mit;
  #   maintainers = with maintainers; [ ];
  #   platforms = platforms.linux;
  # };
}


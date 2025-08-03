{ prev, final, lib, ... }:
let
	pkgs = prev;
in
pkgs.python3Packages.buildPythonPackage rec {
          pname = "adjustor";
          version = "3.10.6";
          pyproject = true;

          src = pkgs.fetchFromGitHub {
    owner = "hhd-dev";
    repo = "adjustor";
    rev = "refs/tags/v${version}";
    hash = "sha256-4kS4CEEqXZm3n8dPO5Fc+l0e4CfxPMHs64WDXh7lg6o=";
  };

          propagatedBuildInputs = with pkgs.python3Packages; [
            pkgs.lsof
	    pkgs.fuse
            setuptools
            rich
            pyroute2
            fuse
            pygobject3
            dbus-python
          ];

	postPatch =''
substituteInPlace src/adjustor/core/acpi.py \
      --replace-fail "[\"modprobe\", \"acpi_call\"]" "[\"${lib.getExe' pkgs.kmod "modprobe"}\", \"acpi_call\"]"
substituteInPlace src/adjustor/fuse/utils.py \
      --replace-fail "cmd = f\"mount" "cmd = f\"${lib.getExe' pkgs.util-linux "mount"}" \
      --replace-fail "{exe_python}" "python"
		'';


		# Fix module discovery for `python -m adjustor`
	  pythonImportsCheck = [ "adjustor" ];
          doCheck = true;

          meta = with lib; {
            homepage = "https://github.com/hhd-dev/adjustor/";
            description = "Adjustor TDP plugin for Handheld Daemon";
            platforms = platforms.linux;
            license = licenses.gpl3;
            maintainers = with maintainers; [ ];
            mainProgram = "adjustor";
          };
        }

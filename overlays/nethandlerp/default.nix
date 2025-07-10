{ prev, final, lib, ... }:
let
  pkgs = prev;
in
pkgs.stdenv.mkDerivation rec {
  pname = "nethandlerp";
  version = "1.0";
  buildInputs = [
    pkgs.libnetfilter_queue
  ];
  src = ./nethandler;

	postPatch =''
substituteInPlace bin/nethandler \
      --replace-fail "/usr/local/share/nethandler" "$out/share/nethandler"
		'';

  installPhase = ''
    install -D -m 755 bin/nethandler $out/bin/nethandler

    mkdir -p $out/share
    cp -r share/nethandler $out/share/nethandler
  '';
}


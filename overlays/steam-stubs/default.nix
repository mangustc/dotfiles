{ prev, final, lib, ... }:
let
  pkgs = prev;
in
pkgs.stdenv.mkDerivation rec {
  pname = "steam-stubs";
  version = "1.0";
  buildCommand = ''
    install -D -m 755 ${./steamos-factory-reset-config} $out/bin/steamos-factory-reset-config
    install -D -m 755 ${./steamos-firmware-update} $out/bin/steamos-firmware-update
    install -D -m 755 ${./steamos-reboot} $out/bin/steamos-reboot
    install -D -m 755 ${./steamos-select-branch} $out/bin/steamos-select-branch
    install -D -m 755 ${./steamos-update} $out/bin/steamos-update
    install -D -m 755 ${./pkexec} $out/bin/pkexec
    install -D -m 755 ${./sudo} $out/bin/sudo
  '';}


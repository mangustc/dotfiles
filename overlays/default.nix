{ pkgs, lib, ... }:
final: prev: {
	gitsshsetup = (import ./gitsshsetup.nix { inherit final prev lib; });
	chlayout = (import ./chlayout.nix { inherit final prev lib; });
	adjustor = (import ./adjustor.nix { inherit final prev lib; });
	nethandlerp = (import ./nethandlerp { inherit final prev lib; });
	steam-stubs = (import ./steam-stubs { inherit final prev lib; });
	handheld-daemon = (import ./handheld-daemon.nix { inherit final prev lib; });
	steam = (import ./steam.nix { inherit final prev lib; });
}

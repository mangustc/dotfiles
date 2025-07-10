{
  pkgs,
  host,
  ...
}: let
	getByHost = first: second:
		if host.name == "main" then first
		else if host.name == "gaming" then second
		else throw "Unsupported host: ${host.name}";
in {
	home.username = "ivan";
	home.homeDirectory = "/home/ivan";
	home.stateVersion = "24.11";
	programs.home-manager.enable = true;

}

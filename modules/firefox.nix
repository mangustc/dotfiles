{ config, lib, pkgs, ... }:

let
	cfg = config.modules.firefox;
in {
	options.modules.firefox = {
		enable = lib.mkEnableOption "Enable firefox";
	};

	config = lib.mkIf cfg.enable {
		programs.firefox = {
			enable = true;
			package = pkgs.firefox.override (args: args // {
				cfg = args.cfg or {};
				extraPrefs = ''
lockPref("browser.tabs.insertAfterCurrent", true);
lockPref("sidebar.verticalTabs", true);
lockPref("sidebar.sidebarRevamp", true);
lockPref("sidebar.main.tools", "history");
lockPref("browser.ctrlTab.sortByRecentlyUsed", true);
lockPref("general.smoothScroll", true);
lockPref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
lockPref("signon.rememberSignons", false);
lockPref("browser.startup.page", 3);
				'';
			});
			policies = {
				DisableTelemetry = true;
				DisableFirefoxStudies = true;
				DisablePocket = true;
				DisableFirefoxAccounts = true;
				DisableAccounts = true;
				DisableFirefoxScreenshots = true;
				OverrideFirstRunPage = "";
				OverridePostUpdatePage = "";
				DontCheckDefaultBrowser = true;
				DisplayBookmarksToolbar = "never"; # alternatives: "always" or "newtab"
				# DisplayMenuBar = "default-off"; # alternatives: "always", "never" or "default-on"
				# SearchBar = "unified"; # alternative: "separate"

				ExtensionSettings = {
					"*".installation_mode = "blocked";
					"uBlock0@raymondhill.net" = {
						install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
						installation_mode = "force_installed";
					};
					"addon@darkreader.org" = {
						install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
						installation_mode = "force_installed";
					};
					"{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
						install_url = "https://addons.mozilla.org/ru/firefox/downloads/latest/return-youtube-dislikes/latest.xpi";
						installation_mode = "force_installed";
					};
					"sponsorBlocker@ajay.app" = {
						install_url = "https://addons.mozilla.org/ru/firefox/downloads/latest/sponsorblock/latest.xpi";
						installation_mode = "force_installed";
					};
					"{74145f27-f039-47ce-a470-a662b129930a}" = {
						install_url = "https://addons.mozilla.org/ru/firefox/downloads/latest/clearurls/latest.xpi";
						installation_mode = "force_installed";
					};
				};
			};
		};
		environment.systemPackages = with pkgs; [
		];
	};
}


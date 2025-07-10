{ final, prev, lib, ... }:
prev.handheld-daemon.overrideAttrs (oldAttrs: {
  name = "handheld-daemon";
	version = "3.17.6";
  src = prev.fetchFromGitHub {
    owner = "hhd-dev";
    repo = "hhd";
    tag = "v3.17.6";
    hash = "sha256-JDTYqVzkdtMwMyMUyc+MABxzEKVsdRuQce9pMS2JnAE=";
  };
  propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ final.adjustor ];
})

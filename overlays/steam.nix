{ final, prev, lib, ... }:
# prev.steam.overrideAttrs (oldAttrs: {
#     extraPkgs = (oldAttrs.extraPkgs or [ ]) ++ [
#       final.steam-stubs
#     ];
#     extraProfile = (oldAttrs.extraProfile or "") + ''
#       export PATH=${final.steam-stubs}/bin:$PATH
#     '';
#     extraBwrapArgs = (oldAttrs.extraBwrapArgs or [ ]) ++ [
#       "--bind /tmp /tmp"
#     ];
#     extraArgs = (oldAttrs.extraArgs or "") + " -steamdeck";
# })
prev.steam.override ({
  extraPkgs = final: [
    prev.dmidecode
    final.steam-stubs
  ];
  extraProfile = ''
    export PATH=${final.steam-stubs}/bin:$PATH
  '';
  extraBwrapArgs = [
    "--bind /tmp /tmp"
  ];
  extraArgs = " -steamdeck";
})

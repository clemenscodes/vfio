{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm;
in
  pkgs.writeShellScriptBin "start.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
      ${pkgs.bash}/bin/set -x
      ${pkgs.systemd}/bin/systemctl stop lactd.service
      ${pkgs.systemd}/bin/systemctl stop display-manager.service
    fi
  ''

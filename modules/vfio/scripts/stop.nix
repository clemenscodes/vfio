{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm;
in
  pkgs.writeShellScriptBin "stop.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
      set -x
      # ${pkgs.systemd}/bin/systemctl start display-manager.service
      # ${pkgs.systemd}/bin/systemctl start lactd.service
    fi
  ''

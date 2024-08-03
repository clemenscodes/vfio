{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm driver;
in
  pkgs.writeShellScriptBin "start.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
      set -x
      ${
      if driver
      then "${pkgs.systemd}/bin/systemctl stop lactd.service"
      else ""
    }
      ${
      if driver
      then "${pkgs.systemd}/bin/systemctl stop display-manager.service"
      else ""
    }
    fi
  ''

{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm driver;
in
  pkgs.writeShellScriptBin "stop.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
      set -x
      ${
      if driver
      then "${pkgs.systemd}/bin/systemctl start lactd.service"
      else ""
    }
      ${
      if driver
      then "${pkgs.systemd}/bin/systemctl start display-manager.service"
      else ""
    }
    fi
  ''

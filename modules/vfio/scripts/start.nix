{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm passthrough;
in
  pkgs.writeShellScriptBin "start.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
      set -x
      ${
      if passthrough
      then "${pkgs.systemd}/bin/systemctl stop lactd.service"
      else ""
    }
      ${
      if passthrough
      then "${pkgs.systemd}/bin/systemctl stop display-manager.service"
      else ""
    }
    fi
  ''

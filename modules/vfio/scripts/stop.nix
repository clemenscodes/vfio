{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm pcis;
in
  pkgs.writeShellScriptBin "stop.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
      ${pkgs.bash}/bin/set -x
      ${builtins.concatStringsSep "\n" (map (pci: "${pkgs.libvirt}/bin/virsh nodedev-reattach ${pci}") pcis)}
      ${pkgs.kmod}/bin/modprobe -r vfio-pci
      sleep 1
      ${pkgs.kmod}/bin/modprobe amdgpu
      sleep 1
      echo 1 > /sys/class/vtconsole/vtcon0/bind
      echo 1 > /sys/class/vtconsole/vtcon1/bind
      ${pkgs.systemd}/bin/systemctl start display-manager.service
      ${pkgs.systemd}/bin/systemctl start lactd.service
    fi
  ''

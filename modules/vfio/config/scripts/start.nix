{
  pkgs,
  config,
}: let
  inherit (config.vfio) vm pcis;
in
  pkgs.writeShellScriptBin "start.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
      ${pkgs.bash}/bin/set -x
      ${pkgs.systemd}/bin/systemctl stop display-manager.service
      ${pkgs.systemd}/bin/systemctl isolate multi-user.target
      ${pkgs.systemd}/bin/systemctl stop lactd.service
      echo 0 > /sys/class/vtconsole/vtcon0/bind
      echo 0 > /sys/class/vtconsole/vtcon1/bind
      ${pkgs.kmod}/bin/modprobe -r amdgpu
      sleep 1
      ${builtins.concatStringsSep "\n" (map (pci: "${pkgs.libvirt}/bin/virsh nodedev-detach ${pci}") pcis)}
      sleep 1
      ${pkgs.kmod}/bin/modprobe vfio-pci
    fi
  ''

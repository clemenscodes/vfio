{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm passthrough;
in
  pkgs.writeShellScriptBin "stop.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "release" ] && [ "$3" = "end" ]; then
      set -x
      ${
      if passthrough
      then ''
        ${pkgs.libvirt}/bin/virsh nodedev-reattach pci_0000_03_00_0
        ${pkgs.libvirt}/bin/virsh nodedev-reattach pci_0000_03_00_1
        ${pkgs.kmod}/bin/modprobe -r vfio-pci
        ${pkgs.kmod}/bin/modprobe amdgpu
        echo 1 > /sys/class/vtconsole/vtcon0/bind
        echo 1 > /sys/class/vtconsole/vtcon1/bind
        ${pkgs.systemd}/bin/systemctl start lactd.service
        ${pkgs.systemd}/bin/systemctl start display-manager.service
      ''
      else ""
    }
    fi
  ''

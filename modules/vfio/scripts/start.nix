{
  pkgs,
  config,
}: let
  inherit (config.virtualisation.vfio) vm passthrough;
in
  pkgs.writeShellScriptBin "start.sh" ''
    if [ "$1" = "${vm}" ] && [ "$2" = "prepare" ] && [ "$3" = "begin" ]; then
      ${pkgs.mullvad}/bin/mullvad disconnect
      ${
      if passthrough
      then ''
        ${pkgs.systemd}/bin/systemctl stop lactd.service
        ${pkgs.systemd}/bin/systemctl stop display-manager.service
        # echo 0 > /sys/class/vtconsole/vtcon0/bind
        # echo 0 > /sys/class/vtconsole/vtcon1/bind
        # ${pkgs.kmod}/bin/modprobe -r amdgpu
        # sleep 1
        # ${pkgs.libvirt}/bin/virsh nodedev-detach pci_0000_03_00_0
        # ${pkgs.libvirt}/bin/virsh nodedev-detach pci_0000_03_00_1
        # ${pkgs.kmod}/bin/modprobe vfio-pci
      ''
      else ""
    }
    fi
  ''

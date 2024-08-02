{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.virtualisation.vfio;
  inherit (cfg) cpu user ovmf hooks;
in {
  imports = [
    ./vnc
    ../options
  ];
  config = lib.mkIf cfg.enable {
    boot = {
      kernelParams = ["${cpu}_iommu=on" "iommu=pt"];
      kernelModules = ["vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"];
    };
    environment = {
      systemPackages = with pkgs; [
        virt-manager
        virt-viewer
        spice
        spice-gtk
        spice-protocol
        libguestfs
        win-virtio
        win-spice
      ];
    };
    systemd = {
      services = {
        libvirtd = {
          preStart = ''
            ln -sf ${hooks.qemu}/bin/qemu /var/lib/libvirt/hooks/qemu
          '';
        };
      };
      tmpfiles = {
        rules = let
          firmware = pkgs.runCommandLocal "qemu-firmware" {} ''
            mkdir $out
            cp ${pkgs.qemu}/share/qemu/firmware/*.json $out
          '';
        in ["L+ /var/lib/qemu/firmware - - - - ${firmware}"];
      };
    };
    virtualisation = {
      libvirtd = {
        inherit (cfg) enable;
        onBoot = "ignore";
        onShutdown = "shutdown";
        allowedBridges = ["virbr0"];
        qemu = {
          runAsRoot = true;
          ovmf = {
            inherit (cfg) enable;
            packages = [ovmf];
          };
          swtpm = {
            inherit (cfg) enable;
          };
        };
        hooks = {
          qemu = {
            start = "${hooks.start}/bin/start.sh";
            stop = "${hooks.stop}/bin/stop.sh";
          };
        };
      };
    };
    users = {
      users = {
        ${user} = {
          extraGroups = ["libvirtd" "kvm" "input"];
        };
      };
    };
    home-manager = lib.mkIf (config.home-manager.enable && cfg.enable) {
      users = {
        ${user} = {
          dconf = {
            settings = {
              "org/virt-manager/virt-manager/connections" = {
                autoconnect = ["qemu:///system"];
                uris = ["qemu:///system"];
              };
            };
          };
        };
      };
    };
  };
}

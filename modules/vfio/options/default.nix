{lib, ...}:
with lib; {
  options = {
    vfio = {
      enable = mkEnableOption "Enable Virtual Function I/O" // {default = false;};
      interface = mkOption {
        type = types.str;
        description = "Name of the guest for which to configure VFIO";
        example = "win11";
      };
      user = mkOption {
        type = types.str;
        description = "User for which to configure VFIO.";
        example = "nixos";
      };
      cpu = mkOption {
        type = types.enum ["intel" "amd"];
        description = "CPU vendor. Either Intel or AMD.";
        example = "intel";
      };
      gpu = mkOption {
        type = types.enum ["amd" "nvidia"];
        description = "GPU vendor. Either AMD or Nvidia.";
        example = "amd";
      };
      pcis = mkOption {
        type = with types; listOf str;
        description = "List of PCI IDs in the form of pci_0000_00_00_0. Will be detached and reattached in libvirts hook cycle.";
        example = ["pci_0000_03_00_0" "pci_0000_03_00_1"];
      };
      ovmf = mkPackageOption pkgs "ovmf" {
        description = "Package to use for OVMF";
        example = "(pkgs.OVMF.override { secureBoot = true; tpmSupport = true; }).fd";
        default =
          (pkgs.OVMF.override {
            secureBoot = true;
            tpmSupport = true;
          })
          .fd;
      };
      hooks = {
        qemu = let
          hook = import ../config/scripts/qemu.nix {inherit pkgs;};
        in
          mkOption {
            type = types.package;
            description = "QEMU script that will configure libvirt hooks. Should not be changed in most cases.";
            default = hook;
            example = hook;
          };
        start = let
          hook = import ../config/scripts/start.nix {inherit pkgs config;};
        in
          mkOption {
            type = types.package;
            description = "Libvirt hook that will run before launching guest.";
            default = hook;
            example = hook;
          };
        stop = let
          hook = import ../config/scripts/stop.nix {inherit pkgs config;};
        in
          mkOption {
            type = types.package;
            description = "Libvirt hook that will run after launching guest.";
            default = hook;
            example = hook;
          };
      };
      vnc = {
        enable = mkEnableOption "Enable VNC port forwarding from outside the host network to the guest." // {default = false;};
        interface = mkOption {
          type = types.str;
          description = "Network interface for which to configure VNC port forwarding to the guest.";
          example = "wlp4s0";
        };
        hook = let
          hook = import ../config/scripts/vnc.nix {inherit pkgs;};
        in
          mkOption {
            type = types.package;
            description = "Libvirt hook that will configure firewall rules for VNC port forwarding.";
            default = hook;
            example = hook;
          };
        host = {
          ip = mkOption {
            type = types.str;
            description = "IP of the host that forwards VNC traffic to the guest.";
            example = "192.168.178.30";
          };
          port = mkOption {
            type = types.int;
            description = "Host VNC port used.";
            example = 5900;
            default = 5900;
          };
        };
        guest = {
          ip = mkOption {
            type = types.str;
            description = "IP of the guest where VNC traffic is routed to.";
            example = "192.168.122.1";
            default = "192.168.122.1";
          };
          port = mkOption {
            type = types.int;
            description = "Guest VNC port used.";
            example = 5900;
            default = 5900;
          };
        };
      };
    };
  };
}

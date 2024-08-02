{
  config,
  lib,
  ...
}: let
  cfg = config.virtualisation.vfio;
  inherit (cfg) vnc;
in {
  config = lib.mkIf (cfg.enable && cfg.vnc.enable) {
    virtualisation = {
      libvirtd = {
        hooks = {
          qemu = {
            vnc = "${vnc.hook}/bin/vnc.sh";
          };
        };
      };
    };
    networking = {
      firewall = {
        allowedTCPPorts = [vnc.host.port];
      };
      nat = {
        inherit (cfg) enable;
        internalInterfaces = [vnc.interface];
        externalInterface = "virbr0";
        forwardPorts = [
          {
            destination = "${vnc.guest.ip}:${builtins.toString vnc.guest.port}";
            proto = "tcp";
            sourcePort = vnc.host.port;
          }
        ];
      };
    };
  };
}

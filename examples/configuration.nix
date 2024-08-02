{
  inputs,
  system,
  ...
}: {
  imports = [
    inputs.vfio.nixosModules.${system}.default
  ];
  virtualisation = {
    vfio = {
      enable = true;
      user = "nixos";
      vm = "win11";
      cpu = "intel";
      gpu = "amd";
      pcis = ["pci_0000_03_00_0" "pci_0000_03_00_1"];
      vnc = {
        enable = true;
        interface = "wlp4s0";
        host = {
          ip = "192.168.178.30";
        };
      };
    };
  };
}

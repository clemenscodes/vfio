inputs: {...}: {
  imports = [
    inputs.nixvirt.nixosModules.default
    ./config
  ];
}

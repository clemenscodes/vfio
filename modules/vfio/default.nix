inputs: {...}: {
  imports = [
    inputs.nixvirt.nixosModules.default
    (import ./config inputs)
  ];
}

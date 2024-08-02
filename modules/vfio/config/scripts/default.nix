{
  pkgs,
  config,
  ...
}: {
  vnc = import ./vnc.nix {inherit pkgs config;};
  qemu = import ./qemu.nix {inherit pkgs;};
  start = import ./start.nix {inherit pkgs config;};
  stop = import ./stop.nix {inherit pkgs config;};
}

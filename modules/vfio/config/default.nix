inputs: {
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.virtualisation.vfio;
  inherit (cfg) vm cpu user ovmf hooks;
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
      libvirt = {
        inherit (cfg) enable;
        swtpm = {
          inherit (cfg) enable;
        };
        connections = {
          "qemu:///system" = {
            domains = [
              {
                # definition = ./win11.xml;
                definition = let
                  source_address = bus: slot: function: {
                    inherit bus slot function;
                    domain = 0;
                  };
                  pci_address = bus: slot: function: (source_address bus slot function) // {type = "pci";};
                  usb_address = port: {
                    inherit port;
                    type = "usb";
                    bus = 0;
                  };
                  drive_address = unit: {
                    inherit unit;
                    type = "drive";
                    controller = 0;
                    bus = 0;
                    target = 0;
                  };
                in
                  inputs.nixvirt.lib.domain.writeXML {
                    type = "kvm";
                    name = vm;
                    uuid = "b8d2d9c9-4088-4288-b668-e12a9fb6d2bb";
                    metadata = with inputs.nixvirt.lib.xml; [
                      (
                        elem "libosinfo:libosinfo" [
                          (attr "xmlns:libosinfo" "http://libosinfo.org/xmlns/libvirt/domain/1.0")
                        ]
                        [
                          (
                            elem "libosinfo:os" [
                              (attr "id" "http://microsoft.com/win/11")
                            ]
                            []
                          )
                        ]
                      )
                    ];
                    memory = {
                      unit = "KiB";
                      count = 16777216;
                    };
                    currentMemory = {
                      unit = "KiB";
                      count = 16777216;
                    };
                    vcpu = {
                      placement = "static";
                      count = 16;
                    };
                    os = {
                      hack = "efi";
                      type = "hvm";
                      arch = "x86_64";
                      machine = "pc-q35-9.0";
                      firmware = {
                        features = [
                          {
                            enabled = false;
                            name = "enrolled-keys";
                          }
                          {
                            enabled = true;
                            name = "secure-boot";
                          }
                        ];
                      };
                      loader = {
                        readonly = true;
                        type = "pflash";
                        secure = true;
                        path = "${pkgs.qemu}/share/qemu/edk2-x86_64-secure-code.fd";
                      };
                      nvram = {
                        template = "${pkgs.qemu}/share/qemu/edk2-i386-vars.fd";
                        path = "/var/lib/libvirt/qemu/nvram/win11_VARS.fd";
                      };
                      boot = {
                        dev = "hd";
                      };
                      bootmenu = {
                        enable = true;
                      };
                    };
                    features = {
                      acpi = {};
                      apic = {};
                      hyperv = {
                        relaxed = {
                          state = true;
                        };
                        vapic = {
                          state = true;
                        };
                        spinlocks = {
                          state = true;
                          retries = 8191;
                        };
                        vendor_id = {
                          state = true;
                          value = "windows";
                        };
                      };
                      kvm = {
                        hidden = {
                          state = true;
                        };
                      };
                      vmport = {
                        state = false;
                      };
                      smm = {
                        state = true;
                      };
                    };
                    cpu = {
                      mode = "host-passthrough";
                      check = "none";
                      migratable = true;
                      topology = {
                        sockets = 1;
                        dies = 1;
                        cores = 8;
                        threads = 2;
                      };
                    };
                    clock = {
                      offset = "localtime";
                      timer = [
                        {
                          name = "rtc";
                          tickpolicy = "catchup";
                        }
                        {
                          name = "pit";
                          tickpolicy = "delay";
                        }
                        {
                          name = "hpet";
                          present = false;
                        }
                        {
                          name = "hypervclock";
                          present = true;
                        }
                      ];
                    };
                    on_poweroff = "destroy";
                    on_reboot = "restart";
                    on_crash = "destroy";
                    pm = {
                      suspend-to-mem = {enabled = false;};
                      suspend-to-disk = {enabled = false;};
                    };
                    devices = {
                      emulator = "/run/libvirt/nix-emulators/qemu-system-x86_64";
                      disk = {
                        type = "file";
                        device = "disk";
                        driver = {
                          name = "qemu";
                          type = "qcow2";
                          discard = "unmap";
                        };
                        source = {
                          file = "/var/lib/libvirt/images/win11.qcow2";
                        };
                        target = {
                          dev = "sda";
                          bus = "sata";
                        };
                        address = drive_address 0;
                      };
                      controller = [
                        {
                          type = "usb";
                          index = 0;
                          model = "qemu-xhci";
                          ports = 15;
                          address = pci_address 2 0 0;
                        }
                        {
                          type = "pci";
                          index = 0;
                          model = "pcie-root";
                        }
                        {
                          type = "pci";
                          index = 1;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 1;
                            port = 16;
                          };
                          address = pci_address 0 2 0 // {multifunction = true;};
                        }
                        {
                          type = "pci";
                          index = 2;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 2;
                            port = 17;
                          };
                          address = pci_address 0 2 1;
                        }
                        {
                          type = "pci";
                          index = 3;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 3;
                            port = 18;
                          };
                          address = pci_address 0 2 2;
                        }
                        {
                          type = "pci";
                          index = 4;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 4;
                            port = 19;
                          };
                          address = pci_address 0 2 3;
                        }
                        {
                          type = "pci";
                          index = 5;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 5;
                            port = 20;
                          };
                          address = pci_address 0 2 4;
                        }
                        {
                          type = "pci";
                          index = 6;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 6;
                            port = 21;
                          };
                          address = pci_address 0 2 5;
                        }
                        {
                          type = "pci";
                          index = 7;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 7;
                            port = 22;
                          };
                          address = pci_address 0 2 6;
                        }
                        {
                          type = "pci";
                          index = 8;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 8;
                            port = 23;
                          };
                          address = pci_address 0 2 7;
                        }
                        {
                          type = "pci";
                          index = 9;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 9;
                            port = 24;
                          };
                          address = pci_address 0 3 0 // {multifunction = true;};
                        }
                        {
                          type = "pci";
                          index = 10;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 10;
                            port = 25;
                          };
                          address = pci_address 0 3 1;
                        }
                        {
                          type = "pci";
                          index = 11;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 11;
                            port = 26;
                          };
                          address = pci_address 0 3 2;
                        }
                        {
                          type = "pci";
                          index = 12;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 12;
                            port = 27;
                          };
                          address = pci_address 0 3 3;
                        }
                        {
                          type = "pci";
                          index = 13;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 13;
                            port = 28;
                          };
                          address = pci_address 0 3 4;
                        }
                        {
                          type = "pci";
                          index = 14;
                          model = "pcie-root-port";
                          hack = {
                            name = "pcie-root-port";
                          };
                          target = {
                            chassis = 14;
                            port = 29;
                          };
                          address = pci_address 0 3 5;
                        }
                        {
                          type = "sata";
                          index = 0;
                          address = pci_address 0 31 2;
                        }
                      ];
                      interface = {
                        type = "bridge";
                        model = {
                          type = "virtio";
                        };
                        source = {
                          bridge = "virbr0";
                        };
                        address = pci_address 1 0 0;
                      };
                      input = [
                        {
                          type = "tablet";
                          bus = "usb";
                          address = usb_address 1;
                        }
                        {
                          type = "mouse";
                          bus = "ps2";
                        }
                        {
                          type = "keyboard";
                          bus = "ps2";
                        }
                      ];
                      tpm = {
                        model = "tpm-tis";
                        backend = {
                          type = "emulator";
                          version = "2.0";
                        };
                      };
                      sound = {
                        model = "ich9";
                        address = pci_address 0 27 0;
                      };
                      audio = {
                        id = 1;
                        type = "none";
                      };
                      hostdev = [
                        {
                          mode = "subsystem";
                          type = "pci";
                          managed = true;
                          driver = {
                            name = "vfio";
                          };
                          source = {
                            address = source_address 3 0 0;
                          };
                          rom = {
                            bar = false;
                          };
                          address = pci_address 3 0 0 // {multifunction = true;};
                        }
                        {
                          mode = "subsystem";
                          type = "pci";
                          managed = true;
                          driver = {
                            name = "vfio";
                          };
                          source = {
                            address = source_address 3 0 1;
                          };
                          rom = {
                            bar = false;
                          };
                          address = pci_address 5 0 0;
                        }
                        {
                          mode = "subsystem";
                          type = "usb";
                          managed = true;
                          source = {
                            vendor = {
                              id = "0x046d";
                            };
                            product = {
                              id = "0xc541";
                            };
                          };
                          address = usb_address 3;
                        }
                        {
                          mode = "subsystem";
                          type = "usb";
                          managed = true;
                          source = {
                            vendor = {
                              id = "0x046d";
                            };
                            product = {
                              id = "0xc539";
                            };
                          };
                          address = usb_address 4;
                        }
                      ];
                      watchdog = {
                        model = "itco";
                        action = "reset";
                      };
                      memballon = {
                        model = "virtio";
                        address = pci_address 4 0 0;
                      };
                    };
                  };
              }
            ];
            networks = [
              {
                definition = inputs.nixvirt.lib.network.writeXML {
                  name = "default";
                  uuid = "fd64df3b-30ed-495c-ba06-b2f292c10d92";
                  forward = {
                    mode = "nat";
                    nat = {
                      port = {
                        start = 1024;
                        end = 65535;
                      };
                    };
                  };
                  bridge = {
                    name = "virbr0";
                    stp = true;
                    delay = 0;
                  };
                  mac = {address = "52:54:00:b2:ca:8d";};
                  ip = {
                    address = "192.168.122.1";
                    netmask = "255.255.255.0";
                    dhcp = {
                      range = {
                        start = "192.168.122.2";
                        end = "192.168.122.254";
                      };
                    };
                  };
                };
                active = true;
              }
            ];
            pools = [
              {
                definition = inputs.nixvirt.lib.pool.writeXML {
                  name = "default";
                  uuid = "8c75fdf7-68e0-4089-8a34-0ab56c7c3c40";
                  type = "dir";
                  target = {
                    path = "/var/lib/libvirt/images";
                    permissions = {
                      mode = "0711";
                      owner = "0";
                      group = "0";
                    };
                  };
                };
              }
            ];
          };
        };
      };
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
  };
}

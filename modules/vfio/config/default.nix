inputs: {
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.virtualisation.vfio;
  inherit (cfg) vm cpu user ovmf hooks driver;
in {
  imports = [
    ./vnc
    ../options
  ];
  config = lib.mkIf cfg.enable {
    boot = {
      kernelParams = ["${cpu}_iommu=on" "iommu=pt"];
      kernelModules = ["vfio" "vfio_pci" "vfio_virqfd" "vfio_iommu_type1"];
      extraModprobeConfig = ''
        options kvm-${cpu} nested=1
      '';
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
                  # drive_address = unit: {
                  #   inherit unit;
                  #   type = "drive";
                  #   controller = 0;
                  #   bus = 0;
                  #   target = 0;
                  # };
                in
                  inputs.nixvirt.lib.domain.writeXML {
                    type = "kvm";
                    name = vm;
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
                      count = 20;
                    };
                    os = {
                      hack = "efi";
                      type = "hvm";
                      arch = "x86_64";
                      machine = "pc-q35-9.0";
                      firmware = {
                        feature = [
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
                      bootmenu = {
                        enable = true;
                      };
                    };
                    features = {
                      acpi = {};
                      apic = {};
                      hyperv = {
                        mode = "custom";
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
                        vpindex = {
                          state = true;
                        };
                        runtime = {
                          state = true;
                        };
                        synic = {
                          state = true;
                        };
                        stimer = {
                          state = true;
                          direct = {
                            state = true;
                          };
                        };
                        reset = {
                          state = true;
                        };
                        vendor_id = {
                          state = true;
                          value = "GenuineIntel";
                        };
                        frequencies = {
                          state = true;
                        };
                        reenlightenment = {
                          state = true;
                        };
                        tlbflush = {
                          state = true;
                        };
                        ipi = {
                          state = true;
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
                      ioapic = {
                        driver = "kvm";
                      };
                    };
                    cpu = {
                      mode = "host-passthrough";
                      check = "none";
                      topology = {
                        sockets = 1;
                        dies = 1;
                        cores = 10;
                        threads = 2;
                      };
                      feature = [
                        {
                          policy = "require";
                          name = "vmx";
                        }
                        {
                          policy = "disable";
                          name = "mpx";
                        }
                        {
                          policy = "disable";
                          name = "hypervisor";
                        }
                      ];
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
                      disk = [
                        {
                          type = "file";
                          device = "disk";
                          driver = {
                            name = "qemu";
                            type = "qcow2";
                            cache = "none";
                            discard = "unmap";
                          };
                          source = {
                            file = "/var/lib/libvirt/images/win11.qcow2";
                          };
                          target = {
                            dev = "vda";
                            bus = "virtio";
                          };
                          boot = {
                            order = 1;
                          };
                          # address = drive_address 0;
                        }
                        {
                          type = "file";
                          device = "cdrom";
                          driver = {
                            name = "qemu";
                            type = "raw";
                          };
                          source = {
                            file = "/var/lib/libvirt/images/win11.iso";
                            startupPolicy = "mandatory";
                          };
                          target = {
                            bus = "sata";
                            dev = "sdb";
                          };
                          boot = {
                            order = 2;
                          };
                          readonly = true;
                          # address = drive_address 1;
                        }
                        {
                          type = "file";
                          device = "cdrom";
                          driver = {
                            name = "qemu";
                            type = "raw";
                          };
                          source = {
                            file = "${inputs.nixvirt.lib.guest-install.virtio-win.iso}";
                          };
                          target = {
                            bus = "sata";
                            dev = "sdc";
                          };
                          readonly = true;
                          # address = drive_address 2;
                        }
                      ];
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
                          type = "sata";
                          index = 0;
                          address = pci_address 0 31 2;
                        }
                      ];
                      interface = {
                        # mac = {
                        #   address = "52:54:00:66:d7:8b";
                        # };
                        type = "bridge";
                        model = {
                          type = "virtio";
                        };
                        source = {
                          bridge = "virbr0";
                        };
                        # address = pci_address 1 0 0;
                      };
                      channel =
                        lib.optional (!driver)
                        {
                          type = "spicevmc";
                          target = {
                            type = "virtio";
                            name = "com.redhat.spice.0";
                          };
                        }
                        ++ [
                          {
                            type = "spiceport";
                            source = {
                              channel = "org.spice-space.webdav.0";
                            };
                            target = {
                              type = "virtio";
                              name = "org.spice-space.webdav.0";
                            };
                          }
                        ];
                      input = [
                        {
                          type = "tablet";
                          bus = "usb";
                          # address = usb_address 1;
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
                        model = "tpm-crb";
                        backend = {
                          type = "emulator";
                          version = "2.0";
                        };
                      };
                      graphics = lib.optional (!driver) [
                        {
                          type = "spice";
                          autoport = true;
                          listen = {
                            type = "none";
                          };
                          image = {
                            compression = false;
                          };
                          gl = {
                            enable = false;
                          };
                        }
                        {
                          type = "vnc";
                          port = -1;
                          autoport = true;
                          hack = "0.0.0.0";
                          listen = {
                            type = "address";
                            address = "0.0.0.0";
                          };
                        }
                      ];
                      sound = {
                        model = "ich9";
                        # address = pci_address 0 27 0;
                      };
                      audio = {
                        id = 1;
                        type =
                          if driver
                          then "none"
                          else "spice";
                      };
                      video = lib.optional (!driver) {
                        model = {
                          type = "qxl";
                          ram = 65536;
                          vram = 65536;
                          vgamem = 16384;
                          heads = 1;
                          primary = true;
                          # address = pci_address 8 1 0;
                        };
                      };
                      hostdev = lib.optional driver [
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
                      memballoon = {
                        model = "virtio";
                        address = pci_address 4 0 0;
                      };
                      # redirdev = [
                      #   {
                      #     bus = "usb";
                      #     type = "spicevmc";
                      #   }
                      #   {
                      #     bus = "usb";
                      #     type = "spicevmc";
                      #   }
                      #   {
                      #     bus = "usb";
                      #     type = "spicevmc";
                      #   }
                      #   {
                      #     bus = "usb";
                      #     type = "spicevmc";
                      #   }
                      # ];
                    };
                  };
              }
            ];
            networks = [
              {
                definition = inputs.nixvirt.lib.network.writeXML {
                  name = "default";
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
                  # mac = {address = "52:54:00:b2:ca:8d";};
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
                active = true;
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

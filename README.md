# NixOS module for VFIO (Virtual Function I/O)

Easily configure single gpu passthrough for QEMU/KVM.

## Installation

Add flake to inputs

```nix
vfio = {
  url = "github:clemenscodes/vfio";
  inputs = {
    nixpkgs = {
      follows = "nixpkgs";
    };
  };
};
```

Now you can import the module in your configuration

```nix
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
```

This configures the system for GPU passthrough and VNC port forwarding from outside the host to the VM,
which is useful to install the GPU drivers after passing through the GPU to the VM for the first time.

Example win11.xml for single GPU passthrough:

```xml
<domain type='kvm'>
  <name>win11</name>
  <uuid>b8d2d9c9-4088-4288-b668-e12a9fb6d2bb</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://microsoft.com/win/11"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit='KiB'>16777216</memory>
  <currentMemory unit='KiB'>16777216</currentMemory>
  <vcpu placement='static'>20</vcpu>
  <os firmware='efi'>
    <type arch='x86_64' machine='pc-q35-9.0'>hvm</type>
    <firmware>
      <feature enabled='no' name='enrolled-keys'/>
      <feature enabled='yes' name='secure-boot'/>
    </firmware>
    <loader readonly='yes' secure='yes' type='pflash'>/nix/store/ynrld58x20v5x22kccs8j14dhzlnlbdr-qemu-9.0.2/share/qemu/edk2-x86_64-secure-code.fd</loader>
    <nvram template='/nix/store/ynrld58x20v5x22kccs8j14dhzlnlbdr-qemu-9.0.2/share/qemu/edk2-i386-vars.fd'>/var/lib/libvirt/qemu/nvram/win11_VARS.fd</nvram>
    <boot dev='hd'/>
    <bootmenu enable='no'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <hyperv mode='custom'>
      <relaxed state='on'/>
      <vapic state='on'/>
      <spinlocks state='on' retries='8191'/>
      <vendor_id state='on' value='windows'/> <!-- This is required, set any value -->
    </hyperv>
    <kvm>
      <hidden state='on'/> <!-- This is required for Nvidia GPUs -->
    </kvm>
    <vmport state='off'/>
    <smm state='on'/>
  </features>
  <cpu mode='host-passthrough' check='none' migratable='on'>
    <topology sockets='1' dies='1' clusters='1' cores='10' threads='2'/>
  </cpu>
  <clock offset='localtime'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
    <timer name='hypervclock' present='yes'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/run/libvirt/nix-emulators/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' discard='unmap'/>
      <source file='/var/lib/libvirt/images/win11.qcow2'/>
      <target dev='sda' bus='sata'/>
      <address type='drive' controller='0' bus='0' target='0' unit='0'/>
    </disk>
    <controller type='usb' index='0' model='qemu-xhci' ports='15'>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x0'/>
    </controller>
    <controller type='pci' index='0' model='pcie-root'/>
    <controller type='pci' index='1' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='1' port='0x10'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0' multifunction='on'/>
    </controller>
    <controller type='pci' index='2' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='2' port='0x11'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x1'/>
    </controller>
    <controller type='pci' index='3' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='3' port='0x12'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x2'/>
    </controller>
    <controller type='pci' index='4' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='4' port='0x13'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x3'/>
    </controller>
    <controller type='pci' index='5' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='5' port='0x14'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x4'/>
    </controller>
    <controller type='pci' index='6' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='6' port='0x15'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x5'/>
    </controller>
    <controller type='pci' index='7' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='7' port='0x16'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x6'/>
    </controller>
    <controller type='pci' index='8' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='8' port='0x17'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x7'/>
    </controller>
    <controller type='pci' index='9' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='9' port='0x18'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0' multifunction='on'/>
    </controller>
    <controller type='pci' index='10' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='10' port='0x19'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x1'/>
    </controller>
    <controller type='pci' index='11' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='11' port='0x1a'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x2'/>
    </controller>
    <controller type='pci' index='12' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='12' port='0x1b'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x3'/>
    </controller>
    <controller type='pci' index='13' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='13' port='0x1c'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x4'/>
    </controller>
    <controller type='pci' index='14' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='14' port='0x1d'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x5'/>
    </controller>
    <controller type='sata' index='0'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1f' function='0x2'/>
    </controller>
    <interface type='network'>
      <mac address='52:54:00:66:d7:8b'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <input type='mouse' bus='ps2'/>
    <input type='keyboard' bus='ps2'/>
    <input type='tablet' bus='usb'>
      <address type='usb' bus='0' port='1'/>
    </input>
    <tpm model='tpm-tis'>
      <backend type='emulator' version='2.0'/>
    </tpm>
    <sound model='ich9'>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x1b' function='0x0'/>
    </sound>
    <audio id='1' type='none'/>
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <driver name='vfio'/>
      <source>
        <address domain='0x0000' bus='0x03' slot='0x00' function='0x0'/>
      </source>
      <rom bar='off'/> <!-- Turn bar off for AMD gpu or you might get a black screen -->
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x0' multifunction='on'/>
    </hostdev>
    <hostdev mode='subsystem' type='pci' managed='yes'>
      <driver name='vfio'/>
      <source>
        <address domain='0x0000' bus='0x03' slot='0x00' function='0x1'/>
      </source>
      <rom bar='off'/>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </hostdev>
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source>
        <vendor id='0x046d'/>
        <product id='0xc541'/>
      </source>
      <address type='usb' bus='0' port='3'/>
    </hostdev>
    <hostdev mode='subsystem' type='usb' managed='yes'>
      <source>
        <vendor id='0x046d'/>
        <product id='0xc539'/>
      </source>
      <address type='usb' bus='0' port='4'/>
    </hostdev>
    <watchdog model='itco' action='reset'/>
    <memballoon model='virtio'>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x0'/>
    </memballoon>
  </devices>
</domain>
```

## Troubleshooting

Turn off ROM BAR for AMD GPUs. Newer AMD GPUs (6000-7000 Series) do not need a patched vBIOS.
Spoof the vendor_id in the XML.

### Blackscreen

Libvirt automatically tries to unload GPU drivers and detaches them.
If you get a black screen, it is most likely that some programs are using the drivers such that they can't be unloaded.

#### modprobe: FATAL: Module amdgpu is in use.

I had an issue where the output of `lsmod | grep amdgpu` resulted in the following output after stopping the display-server.

```
amdgpu              13955072  1
amdxcp                 12288  1 amdgpu
drm_exec               12288  1 amdgpu
gpu_sched              65536  1 amdgpu
drm_buddy              20480  1 amdgpu
drm_suballoc_helper    12288  1 amdgpu
drm_ttm_helper         12288  1 amdgpu
ttm                   102400  2 amdgpu,drm_ttm_helper
drm_display_helper    258048  1 amdgpu
i2c_algo_bit           20480  1 amdgpu
video                  77824  1 amdgpu
backlight              28672  2 video,amdgpu
```

A program is still using the drivers, but we don't know which one.
This will prevent the `amdgpu` driver from being unloaded.
You will have to figure out which service uses the driver.
In my case it was lactd.service and after stopping it `modprobe -r amdgpu` ran successfully.

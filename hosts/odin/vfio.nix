{pkgs, ...}: let
  # Extra SMBIOS structures QEMU never emits, appended to the guest tables via
  # -smbios file=. Contains this host's real L1/L2/L3 cache (type 7, byte
  # identical - the passthrough CPU is the same 9800X3D) plus fabricated memory
  # module (6), port connector (8), system slot (9), voltage probe (26), cooling
  # device (27) and temperature probe (28) tables. Windows populates its WMI
  # classes (Win32_Fan, Win32_VoltageProbe, CIM_TemperatureSensor, CIM_Slot, ...)
  # from these, so they return >=1 instance instead of the empty result that
  # gives a VM away. The total also pushes the structure count past 40. Handles
  # live in
  # ranges QEMU's 0xNN00 scheme doesn't use, and -smbios file= only conflicts
  # with -smbios type= for the *same* type (we don't set 6/7/8/9/26/27/28 that
  # way). Verified end to end by booting a Linux guest under this OVMF and
  # confirming dmidecode enumerates every structure. Contents are generic
  # hardware descriptors - nothing machine-private.
  extraSmbios = pkgs.runCommandLocal "win11-extra-smbios.bin" {} ''
    ${pkgs.python3}/bin/python3 ${./win11-smbios.py} > "$out"
  '';

  # Supplementary ACPI table (SSDT) adding a passive thermal zone; see
  # win11-thermal.dsl. Compiled with iasl and handed to the guest via
  # -acpitable so Windows' thermal-zone counters aren't empty (QEMU emits no
  # thermal zone of its own).
  thermalAcpi = pkgs.runCommandLocal "win11-thermal.aml" {
    nativeBuildInputs = [pkgs.acpica-tools];
  } ''
    cp ${./win11-thermal.dsl} thermal.dsl
    iasl thermal.dsl
    cp thermal.aml "$out"
  '';

  # WSMT (Windows SMM Security Mitigations Table); see win11-wsmt.py. Real UEFI
  # boards ship one and QEMU does not, so its absence is a VM tell.
  wsmtAcpi = pkgs.runCommandLocal "win11-wsmt.bin" {} ''
    ${pkgs.python3}/bin/python3 ${./win11-wsmt.py} > "$out"
  '';
in {
  imports = [
    ../common/base/services/vfio-vm.nix
  ];

  services.vfioVm = {
    enable = true;
    vmName = "win11";
    primaryDevice = "0000:03:00.0";

    devices = [
      {
        pci = "0000:03:00.0";
        hostDriver = "amdgpu";
        resetMethod = "sbr";
        romFile = "/var/lib/libvirt/vbios/rx7900-03-00-0.rom";
        romBar = "off";
        guestAddress = {
          bus = "0x05";
          multifunction = true;
        };
      }
      {
        pci = "0000:03:00.1";
        hostDriver = "snd_hda_intel";
        guestAddress = {
          bus = "0x05";
          function = "0x1";
        };
      }
      {
        pci = "0000:0d:00.0";
        hostDriver = "xhci_hcd";
        guestAddress.bus = "0x07";
      }
    ];

    user = "jack";
    userUid = 1000;

    # The RX 7900 XT (Navi 31) cannot be reset well enough for amdgpu to
    # re-probe it after the VM releases it - it hits a kernel BUG() in
    # amdgpu_device_mm_access during IP discovery. A bus reset (the only reset
    # this ASIC exposes) recovers PCI config space but not the GPU's PSP state,
    # so the only reliable recovery is a full cold init. Reboot on VM shutdown
    # instead of attempting a live rebind that would wedge the host.
    hostRecovery = "reboot";

    # restartServices defaults to these in reverse, so openrgb comes back before
    # greetd takes the display. Unused while hostRecovery = "reboot" (the reboot
    # brings the whole session back), but kept for if the GPU ever gains a
    # working reset.
    stopServices = [
      "greetd.service"
      "openrgb.service"
    ];

    desktopDisplayName = "Windows";
    desktopComment = "Start the Windows 11 stealth VM with GPU passthrough";
    desktopIcon = "windows";

    domain = {
      enable = true;
      uuid = "508a7af7-d0ce-41e7-8fa8-d58005d9fabb";

      # Advertise S3 so GetPwrCapabilities reports a sleep state - a real PC
      # supports one, and a machine that supports none looks like a VM.
      suspendToMem = true;

      memoryKiB = 24576000;
      vcpus = 14;

      topology = {
        cores = 7;
        threads = 2;
      };

      # 7 physical cores with both their SMT siblings, leaving core 0 and its
      # sibling (8) to the host and the emulator.
      vcpuPin = [
        "1"
        "9"
        "2"
        "10"
        "3"
        "11"
        "4"
        "12"
        "5"
        "13"
        "6"
        "14"
        "7"
        "15"
      ];
      emulatorPin = "0,8";

      emulator = "${pkgs.qemu-stealth}/bin/qemu-system-x86_64";
      machine = "pc-q35-10.2";

      # Hide the hypervisor entirely: no Hyper-V enlightenments, so cpuid leaf
      # 0x40000000 reads blank and Windows creates no Hyper-V objects (both are
      # given away with enlightenments on). Costs some guest performance, worth
      # it for a bare-metal disguise on an analysis VM.
      hyperv = false;

      # The GPU sits on guest bus 0x05 and the passthrough USB on 0x07, so 7
      # root ports is the floor that keeps those bus numbers unchanged. Going
      # lower would renumber the guest's PCI buses and make Windows re-enumerate
      # the passed-through hardware. This trims the root-port count from
      # libvirt's 14 down to 7.
      pcieRootPorts = 7;

      # Use Intel ioh3420 root ports (8086:3420) instead of the Red Hat
      # pcie-root-port (1b36:000c) so nothing shows up under VEN_1B36. Revert to
      # "pcie-root-port" if the GPU misbehaves behind the older gen2 port.
      pcieRootPortModel = "ioh3420";

      network.mac = "00:1b:21:7a:3c:91";

      disks = [
        {
          type = "block";
          device = "disk";
          source = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_250GB_S2R6NX0J422044L";
          target = "sda";
          serial = "S2R6NX0J422044L";
          cache = "none";
          io = "native";
          discard = "unmap";
          unit = 0;
        }
      ];

      # Copied from this machine's own DMI so the guest reads back the host's
      # real board rather than QEMU's defaults.
      smbios = [
        {
          name = "bios";
          entries = {
            vendor = "American Megatrends International, LLC.";
            version = "3.40";
            date = "08/27/2025";
            release = "5.35";
          };
        }
        {
          name = "system";
          entries = {
            manufacturer = "ASRock";
            product = "X870 Steel Legend WiFi";
            version = "Default string";
            serial = "R12-A870SL01";
            uuid = "508a7af7-d0ce-41e7-8fa8-d58005d9fabb";
            sku = "Default string";
            family = "Default string";
          };
        }
        {
          name = "baseBoard";
          entries = {
            manufacturer = "ASRock";
            product = "X870 Steel Legend WiFi";
            version = "Default string";
            serial = "B12-A870SL01";
            asset = "Default string";
            location = "Default string";
          };
        }
        {
          name = "chassis";
          entries = {
            manufacturer = "Default string";
            version = "Default string";
            serial = "Default string";
            asset = "Default string";
            sku = "Default string";
          };
        }
      ];

      extraQemuArgs = [
        "-smbios"
        "type=17,manufacturer=Samsung,part=M425R3GA3BB0-CQKOL,speed=6000"
        # QEMU stamps "QEMU" into SMBIOS type 4 (processor) even under
        # host-passthrough, readable straight from the raw tables. Override
        # every string field with the real AMD values so no QEMU marker remains.
        # Commas inside a value are doubled per QEMU's option parser.
        "-smbios"
        "type=4,sock_pfx=AM5,manufacturer=Advanced Micro Devices,, Inc.,version=AMD Ryzen 7 9800X3D 8-Core Processor,max-speed=5200,current-speed=4700"
        # Inject the extra SMBIOS structures (cache + sensors + slots/ports; see
        # extraSmbios above) so Windows' hardware/sensor WMI classes aren't empty.
        "-smbios"
        "file=${extraSmbios}"
        # Add the passive thermal zone (see thermalAcpi above).
        "-acpitable"
        "file=${thermalAcpi}"
        # Add the WSMT table real UEFI firmware ships (see wsmtAcpi above).
        "-acpitable"
        "file=${wsmtAcpi}"
      ];
    };
  };
}

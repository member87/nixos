{
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
      }
      {
        pci = "0000:03:00.1";
        hostDriver = "snd_hda_intel";
      }
    ];

    user = "jack";
    userUid = 1000;

    stopServices = [
      "greetd.service"
      "openrgb.service"
    ];

    restartServices = [
      "greetd.service"
    ];

    desktopDisplayName = "Windows";
    desktopComment = "Start the Windows 11 gaming VM with GPU passthrough";
    desktopIcon = "windows";
  };
}

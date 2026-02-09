# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  hostname,
  pkgs,
  ...
}: {
  services.udev.extraRules = ''
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2581", ATTRS{idProduct}=="1b7c|2b7c|3b7c|4b7c", TAG+="uaccess", TAG+="udev-acl"
    SUBSYSTEMS=="usb", ATTRS{idVendor}=="2c97", TAG+="uaccess", TAG+="udev-acl"
    KERNEL=="hidraw*", ATTRS{idVendor}=="2c97", MODE="0666"
    
    # Virtual FIDO2/U2F device for WebAuthn
    KERNEL=="uhid", SUBSYSTEM=="misc", MODE="0660", TAG+="uaccess"
  '';

  fileSystems."/run/1TBSSD" = {
    device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_1TB_S3YBNB0K504591D-part1";
    fsType = "ext4";
    options = [
      "rw"
      "data=ordered"
      "relatime"
    ];
  };

  hardware.i2c.enable = true;
  hardware.opengl.enable = true;
  services.hardware.openrgb.enable = true;

  environment.systemPackages = with pkgs; [
    talosctl
    kubectl
    gamescope
    stable.darktable
    libfido2  # Provides virtual authenticator tools
  ];
}

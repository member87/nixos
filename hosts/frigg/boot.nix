{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  boot.isContainer = true;

  systemd.mounts = [
    {
      where = "/sys/kernel/debug";
      enable = false;
    }
  ];
}

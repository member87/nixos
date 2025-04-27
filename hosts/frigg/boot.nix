{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  boot.isContainer = true;
  boot.system.mask = ["sys-kernel-debug.mount"];
}

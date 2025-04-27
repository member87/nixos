{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];

  boot.isContainer = true;
}

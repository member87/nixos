{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    efibootmgr
  ];
}

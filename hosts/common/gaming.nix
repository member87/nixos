{pkgs, ...}: {
  programs = {
    steam.enable = true;
    gamemode.enable = true;
  };

  environment.systemPackages = with pkgs; [
    protontricks
    r2modman
    wineWow64Packages.stable
  ];
}

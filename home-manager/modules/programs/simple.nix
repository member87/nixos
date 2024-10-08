{ lib, config, ... }:

{
  programs = { 
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };

  services = {
    dunst.enable = true;
  };
}

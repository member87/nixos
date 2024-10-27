{
  lib,
  config,
  ...
}: {
  programs = {
    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };

    btop.enable = true;
  };

  services = {
    dunst.enable = true;
  };
}

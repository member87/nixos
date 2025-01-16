{ pkgs, ... }:
{
  services.openssh = {
    enable = false;
    settings = {
      PasswordAuthentication = false;
    };
  };

  programs.ssh = {
    enableAskPassword = true;
    askPassword = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";
  };
}

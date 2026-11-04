{pkgs, ...}: {
  services.openssh = {
    enable = true;
    # Key only: jack has passwordless sudo, so a guessed password would be root.
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      X11Forwarding = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  programs.ssh = {
    enableAskPassword = true;
    askPassword = "${pkgs.lxqt.lxqt-openssh-askpass}/bin/lxqt-openssh-askpass";
  };
}

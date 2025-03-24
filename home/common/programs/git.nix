{
  lib,
  config,
  ...
}: {
  programs.git = {
    enable = true;

    userName = "Jack";
    userEmail = "43416057+member87@users.noreply.github.com";

    extraConfig = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";
    };
  };
}

{
  lib,
  config,
  ...
}: {
  programs.git = {
    enable = true;

    settings = {
      commit.gpgsign = true;
      gpg.format = "ssh";
      user.signingkey = "~/.ssh/id_ed25519.pub";

      user = {
        email = "43416057+member87@users.noreply.github.com";
        name = "Jack";
      };
    };
  };
}

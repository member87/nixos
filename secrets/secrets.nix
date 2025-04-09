let
  jack = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSro9NaLVyjSrwgqFT1opk4Szwk08Ag7lrJoDDwhT4a";

  users = [jack];
in {
  "jack.age".publicKeys = users;
}

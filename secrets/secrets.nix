let
  odin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSro9NaLVyjSrwgqFT1opk4Szwk08Ag7lrJoDDwhT4a";
  thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKB5yZ34+4OSm/TIe0WEbvHRy8HR5QH22Im5K1UG4f84";

  systems = [
    odin
    thor
  ];
in {
  # Wireguard Configs
  "wiregaurd_proton_london.age".publicKeys = systems;
}

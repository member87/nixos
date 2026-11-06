let
  # jack's ~/.ssh/id_ed25519 on each host.
  jack-odin = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL3UXwi2ZmExP4hZLwcaRaryfSlUm9XTTwbMLv1pliEi";
  jack-thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKB5yZ34+4OSm/TIe0WEbvHRy8HR5QH22Im5K1UG4f84";

  # /etc/ssh/ssh_host_ed25519_key.pub, which decrypts at boot without depending on the user
  # key. odin's is not added yet.
  thor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATZJVC37V4itNzQxscKTf5jnSZLc09/XogeYq4lnR4b";

  hosts = [
    jack-odin
    jack-thor
    thor
  ];
in {
  "wireguard_proton_london.age".publicKeys = hosts;
  # the music drawer's Spotify app (home/common/desktop/quickshell)
  "spotify_client_id.age".publicKeys = hosts;
}

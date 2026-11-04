{username, ...}: {
  age.secrets."wireguard/london.conf" = {
    file = ../../../secrets/wireguard_proton_london.age;
    owner = username;
  };
}

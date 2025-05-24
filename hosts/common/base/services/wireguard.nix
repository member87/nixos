{inputs, ...}: {
  age.secrets."wireguard/london.conf" = {
    file = ../../../../secrets/wiregaurd_proton_london.age;
    owner = "jack";
  };
}

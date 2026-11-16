# BeamMP: the server runs here, bound to localhost, and friends reach it over tailcat.
# - Play here: start BeamNG through BeamMP-Launcher, Direct Connect to 127.0.0.1:30814.
# - Invite: send the address in /var/lib/beammp-tailcat/address, privately (it is the
#   only credential). They run `beamcat connect <address>` (`nix build .#beamcat-windows`
#   for the .exe) and Direct Connect to 127.0.0.1:30814.
# - Mods: add zips to clientMods, or copy them into /var/lib/beammp-server/Resources/Client
#   and `systemctl restart beammp-server`.
{
  config,
  outputs,
  pkgs,
  username,
  ...
}: {
  imports = [outputs.nixosModules.beammp-server];

  age.secrets.beammp-auth-key.file = ../../secrets/beammp_auth_key.age;

  services.beammp-server = {
    enable = true;
    authKeyFile = config.age.secrets.beammp-auth-key.path;
    name = "nix server";
    tailcat.enable = true;
  };

  # Drop mods into Resources/ and read the tailcat address without sudo.
  users.users.${username}.extraGroups = ["beammp"];

  environment.systemPackages = [pkgs.beammp-launcher];
}

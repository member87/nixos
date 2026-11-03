# Nightly updates from the home-ops nix cache (home-ops apps/nix-cache).
#
# At 01:00 a builder in the cluster runs `nix flake update`, builds every nixosConfiguration
# and homeConfiguration, pushes what no public cache has to nix-cache.lab.jackhumes.com and
# then pushes the new flake.lock to main. At 05:00 both hosts upgrade from GitHub: the system
# with system.autoUpgrade, Home Manager with a user timer. Everything they need is already
# built, either in that cache or on a public one.
#
# They upgrade from github:member87/nixos, not this checkout, so they get exactly the lock
# the builder built. Pull before `nh os switch` / `nh home switch` from ~/nixos, or the
# local, older lock rolls the machine back.
{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  username,
  ...
}: let
  flake = "github:member87/nixos";
  home-manager = inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager;
in {
  nix.settings = {
    substituters = ["https://nix-cache.lab.jackhumes.com/jackhumes"];
    trusted-public-keys = ["jackhumes:zfC8kjhNVZS6Xm5LyWaGu85eTwk0c8zuYFBzW7G2bGA="];
    # The cache is LAN-only: away from home, give up on it quickly and build or use the
    # public caches instead.
    connect-timeout = 5;
    fallback = true;
  };

  system.autoUpgrade = {
    enable = true;
    inherit flake;
    dates = "05:00";
    randomizedDelaySec = "30min";
    # Run at the next boot or wake if the machine was off or asleep at 05:00.
    persistent = true;
    operation = "switch";
    # --upgrade refreshes channels; the flake's lock is the only input.
    upgrade = false;
    allowReboot = false;
  };

  # Home Manager stays standalone (`nh home switch`), so it upgrades on its own timer, after
  # the system's window.
  systemd.user.services.home-manager-auto-upgrade = {
    unitConfig.ConditionUser = username;
    after = ["network-online.target"];
    path = [config.nix.package pkgs.git];
    serviceConfig.Type = "oneshot";
    script = ''
      ${lib.getExe home-manager} switch --flake ${lib.escapeShellArg "${flake}#${username}@${hostname}"}
    '';
  };
  systemd.user.timers.home-manager-auto-upgrade = {
    description = "Home Manager upgrade from ${flake}";
    unitConfig.ConditionUser = username;
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "05:40";
      RandomizedDelaySec = "20min";
      Persistent = true;
    };
  };
}

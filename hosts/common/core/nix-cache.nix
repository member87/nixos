# Nightly updates from the home-ops nix cache (home-ops apps/nix-cache).
#
# At 01:00 a builder in the cluster runs `nix flake update`, builds every nixosConfiguration
# (Home Manager included), pushes what no public cache has to nix-cache.lab.jackhumes.com and
# then pushes the new flake.lock to main. At 05:00 both hosts upgrade from GitHub with
# system.autoUpgrade. Everything they need is already built, either in that cache or on a
# public one.
#
# They upgrade from github:member87/nixos, not this checkout, so they get exactly the lock
# the builder built. Pull before `nh os switch` from ~/nixos, or the local, older lock rolls
# the machine back.
{
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
    flake = "github:member87/nixos";
    dates = "05:00";
    randomizedDelaySec = "30min";
    # Run at the next boot or wake if the machine was off or asleep at 05:00.
    persistent = true;
    operation = "switch";
    # --upgrade refreshes channels; the flake's lock is the only input.
    upgrade = false;
    allowReboot = false;
  };
}

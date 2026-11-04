{
  programs.hyprland = {
    enable = true;
    # nixpkgs builds Hyprland with UWSM support; the module's default (false) rebuilds it,
    # so this keeps it on cache.nixos.org. The greeter still starts start-hyprland
    # directly; uwsm just adds an unused "Hyprland (UWSM)" session.
    withUWSM = true;
  };
}

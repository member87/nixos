
# NixOS Configuration 

[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&logo=NixOS&logoColor=white)](https://nixos.org)
[![Built with Nix](https://img.shields.io/badge/Built_With-Nix-5277C3.svg?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-purple.svg?style=for-the-badge)](https://hyprland.org/)


| Host  | Purpose | Description |
|------|---------|-------------|
| `odin` | Workstation | Primary desktop workstation  |
| `thor` |  Laptop | Framework laptop  |

## Layout

- `hosts/default.nix` applies to every host: overlays, Home Manager (as a NixOS module, `home/`) and `hosts/common/core`.
- `hosts/<host>/default.nix` is each host's entry point and picks its roles: `common/desktop`, `common/dev.nix`, `common/gaming.nix`.
- `modules/nixos/` holds reusable modules (`vfio-vm`), exported as `nixosModules`.
- `pkgs/` holds custom packages, available as `pkgs.<name>` and `nix build .#<name>`.

`nix flake check` builds both hosts, Home Manager included.

## Updates

A builder in the home-ops cluster (`apps/nix-cache`) runs `nix flake update` every night at 01:00 and builds every host. It pushes what no public cache has to `https://nix-cache.lab.jackhumes.com/jackhumes`, then commits the new `flake.lock` to `main` as `chore(flake): update inputs`. At 05:00 both hosts upgrade from `github:member87/nixos` through `system.autoUpgrade` (`hosts/common/core/nix-cache.nix`), Home Manager included. The Grafana dashboard *Nix Cache* shows the build.

`main` moves every night, so run `git pull` before `nh os switch`. Switching from an older local `flake.lock` rolls the machine back to older inputs.

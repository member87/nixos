
# NixOS Configuration 

[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&logo=NixOS&logoColor=white)](https://nixos.org)
[![Built with Nix](https://img.shields.io/badge/Built_With-Nix-5277C3.svg?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-purple.svg?style=for-the-badge)](https://hyprland.org/)


| Host  | Purpose | Description |
|------|---------|-------------|
| `odin` | Workstation | Primary desktop workstation  |
| `thor` |  Laptop | Framework laptop  |

## Updates

A builder in the home-ops cluster (`apps/nix-cache`) runs `nix flake update` every night at 01:00 and builds every host and Home Manager config. It pushes what no public cache has to `https://nix-cache.lab.jackhumes.com/jackhumes`, then commits the new `flake.lock` to `main` as `chore(flake): update inputs`. At 05:00 both hosts upgrade from `github:member87/nixos`: the system through `system.autoUpgrade`, Home Manager through the `home-manager-auto-upgrade` user timer (`hosts/common/base/nix-cache.nix`). The Grafana dashboard *Nix Cache* shows the build.

`main` moves every night, so run `git pull` before `nh os switch` or `nh home switch`. Switching from an older local `flake.lock` rolls the machine back to older inputs.

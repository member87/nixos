# NixOS configuration

Personal, flake-based NixOS and Home Manager configuration for two x86_64 Linux machines. It defines complete system configurations, user environments, custom packages, overlays, encrypted secrets, and a declarative Hyprland desktop.

> This is an opinionated personal configuration. Host modules contain machine- and network-specific details, including disk layouts, mounts, hardware settings, and private infrastructure. Do not deploy a host configuration unchanged to different hardware.

## Hosts

| Host | Role | Notable configuration |
| --- | --- | --- |
| `odin` | Desktop workstation | VFIO virtual-machine support, Star Citizen tooling, and a dedicated game-data mount |
| `thor` | Framework laptop | Framework AMD AI 300-series hardware module, fan control, power settings, and laptop peripherals |

Both hosts share the base system and the `jack` Home Manager profile. Their hardware and disk definitions live under `hosts/<host>/`.

## What is managed

- **NixOS:** host boot, disks, networking, services, users, desktop prerequisites, Docker, and system packages.
- **Home Manager:** Hyprland, terminal and shell tooling, notifications, media applications, browser configuration, and other user programs.
- **Inputs:** unstable and stable `nixpkgs`, Home Manager, Hyprland, agenix, disko, hardware modules, and application-specific flakes.
- **Local packages and overlays:** `pkgs/` exports custom packages; `overlays/` exposes additions, modifications, and stable packages.
- **Secrets:** agenix-encrypted files are stored in `secrets/`. Their recipients are declared in `secrets/secrets.nix`; private keys are never committed.

## Repository layout

```text
flake.nix             Flake inputs and exported system, Home Manager, package, and overlay outputs
hosts/                Host-specific hardware, disks, boot, and NixOS modules
hosts/common/         Shared NixOS base, services, packages, and desktop configuration
home/                 Home Manager profile and shared desktop/program modules
pkgs/                 Custom derivations
overlays/             nixpkgs overlays
secrets/              agenix-encrypted secrets and recipient declarations
lib/                  Flake and host-construction helpers
install.sh            Destructive bare-metal installation helper
```

## Requirements

Run commands from a NixOS installation with flakes enabled. The configuration enables `nix-command` and `flakes` after it is applied, but they must be available for the initial deployment. Rebuilding a host requires `sudo`; applying Home Manager requires the `home-manager` command supplied by the flake input.

Clone the repository to the path configured in `flake.nix` (`/home/jack/nixos`), or update `flakePath` if using another location or username.

```sh
git clone git@github.com:member87/nixos.git /home/jack/nixos
cd /home/jack/nixos
```

## Apply configuration

### System

Build and activate a host configuration:

```sh
sudo nixos-rebuild switch --flake .#odin
# or
sudo nixos-rebuild switch --flake .#thor
```

Use `test` instead of `switch` to activate changes only until the next reboot:

```sh
sudo nixos-rebuild test --flake .#thor
```

### Home Manager

Apply the matching user profile after changing files under `home/`:

```sh
home-manager switch --flake .#jack@odin
# or
home-manager switch --flake .#jack@thor
```

## Fresh installation

Each host imports a host-specific `disks.nix` through disko. Review the target host's disk layout, hardware configuration, secrets, and any environment-specific mounts before installing.

`install.sh` wipes the selected host's disks, creates the disk layout, installs the NixOS configuration, and copies this checkout to the target home directory. It must be run as a regular user and prompts before the destructive operation.

```sh
./install.sh <host> [user]
# example: ./install.sh thor jack
```

Do not run this script on an existing machine unless its disk layout has been reviewed and data is backed up.

## Secrets

Secrets are encrypted with agenix. The system configuration expects the identity at `/home/jack/.ssh/id_ed25519`. Add or rotate a secret with agenix, then commit only the encrypted `.age` file and its recipient declaration—never a private key or plaintext secret.

```sh
agenix -e secrets/<name>.age
```

## Development

Format Nix files and evaluate the flake before committing. The package set includes unfree software, so run the flake check impurely with the explicit opt-in:

```sh
nix fmt
NIXPKGS_ALLOW_UNFREE=1 nix flake check --impure
```

Update flake inputs deliberately and review the resulting lock-file diff:

```sh
nix flake update
```

For a change limited to a single host, build or test that host before activating it. For Home Manager-only changes, use the corresponding `home-manager switch` command above.

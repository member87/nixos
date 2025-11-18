
# NixOS Configuration 

[![NixOS Unstable](https://img.shields.io/badge/NixOS-unstable-blue.svg?style=for-the-badge&logo=NixOS&logoColor=white)](https://nixos.org)
[![Built with Nix](https://img.shields.io/badge/Built_With-Nix-5277C3.svg?style=for-the-badge&logo=nixos&logoColor=white)](https://builtwithnix.org)
[![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-purple.svg?style=for-the-badge)](https://hyprland.org/)

My personal NixOS system configurations using Flakes, featuring Hyprland desktop environment, home-manager, and various self-hosted services.


## 🖥️ Hosts

| Host  | Purpose | Description |
|------|---------|-------------|
| `odin` | Workstation | Primary desktop workstation  |
| `thor` |  Laptop | Framework laptop  |
| `frigg` | Homelab | K3s server node |

## Features

- **Hyprland** - A dynamic tiling Wayland compositor
- **Home Manager** - User environment configuration
- **Agenix** - Secrets management
- **Custom EWW Bar** - Stylish system bar with system controls
- **K3s** - Lightweight Kubernetes for self-hosting

##  Self-Hosted Services

> Currently moving over from a docker-compose deployment to K3S.

The following services are self-hosted on the K3s cluster:

| Service | Description |
|---------|-------------|
| [`cert-manager`](https://cert-manager.io/) | Certificate management for Kubernetes. Automates the management and issuance of TLS certificates |
| [`glance`](https://github.com/glanceapp/glance) | Homelab dashboard - A clean and modern interface to monitor services |
| [`longhorn`](https://longhorn.io/) | Cloud native distributed block storage for Kubernetes |
| [`metallb`](https://metallb.universe.tf/) | Load-balancer implementation for bare metal Kubernetes clusters |
| [`pihole`](https://pi-hole.net/) | Network-wide ad blocking and local DNS management |
| [`prometheus`](https://prometheus.io/) | Monitoring and alerting toolkit for Kubernetes clusters |
| [`traefik`](https://traefik.io/) | Modern HTTP reverse proxy and load balancer for microservices |


## Structure

```nix
.
├── flake.nix         # Flake configuration
├── hosts/            # Host-specific configurations
│   ├── odin/         # Desktop configuration
│   ├── thor/         # Laptop configuration
│   └── frigg/        # Server configuration
├── home/             # Home-manager configurations
│   └── common/       # Shared home configurations
├── secrets/          # Agenix encrypted secrets
└── argocd/           # K3S argocd deployment yaml files
```

## Installation

1. Clone the repo
```
nix-shell -p git
git clone git@github.com:member87/nixos.git
cd nixos
```

2. Run installation script
```
./install.sh {host} {user}
```

## Development

### AGS

Generate AGS types using

```bash
ags types -u -v -d /path/to/ags
```


## Acknowledgments

- [NixOS](https://nixos.org/)
- [Home Manager](https://github.com/nix-community/home-manager)
- [Hyprland](https://hyprland.org/)
- [Agenix](https://github.com/ryantm/agenix)


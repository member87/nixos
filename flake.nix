{
  description = "NixOS and Home Manager configuration for odin and thor";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Reached through pkgs.stable (overlays/default.nix).
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # No follows: nix-citizen's cache holds wine-astral, dxvk and the rest built against its
    # own nixpkgs and nix-gaming; following ours would rebuild them on every nixpkgs bump.
    nix-citizen.url = "github:LovingMelody/nix-citizen";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # No nixpkgs follows, so the package matches vicinae.cachix.org instead of building here.
    # Pinned to a release tag; move it to a newer tag to update.
    vicinae.url = "github:vicinaehq/vicinae/v0.29.2";
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.vicinae.follows = "vicinae";
    };

    nixcord.url = "github:FlameFlag/nixcord";

    omp.url = "github:can1357/oh-my-pi";

    # omp skills (not flakes; linked into ~/.omp/agent/skills by home-manager)
    skill-impeccable = {
      url = "github:pbakaus/impeccable";
      flake = false;
    };
    skill-taste = {
      url = "github:Leonxlnx/taste-skill";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (self) outputs;
    stateVersion = "26.05";
    username = "jack";
    flakePath = "/home/${username}/nixos";

    libx = import ./lib {
      inherit
        inputs
        outputs
        stateVersion
        username
        flakePath
        ;
    };
  in {
    packages = libx.forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    nixosModules = import ./modules/nixos;

    nixosConfigurations = {
      odin = libx.mkHost {hostname = "odin";};
      thor = libx.mkHost {hostname = "thor";};
    };

    homeConfigurations = {
      "${username}@odin" = libx.mkHome {hostname = "odin";};
      "${username}@thor" = libx.mkHome {hostname = "thor";};
    };

    formatter = libx.forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays {inherit inputs;};
  };
}

{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nix-gaming.url = "github:fufexan/nix-gaming";

    ghostty.url = "github:ghostty-org/ghostty";

    hyprland.url = "github:hyprwm/Hyprland";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixpkgs-stable,
    agenix,
    spicetify-nix,
    nixos-hardware,
    ...
  } @ inputs: let
    inherit (self) outputs;
    stateVersion = "24.11";
    username = "jack";
    flakePath = "/home/jack/nixos";

    libx = import ./lib {
      inherit
        self
        inputs
        outputs
        stateVersion
        username
        flakePath
        ;
    };
  in {
    packages = libx.forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        import ./pkgs {inherit pkgs;}
    );

    nixosConfigurations = {
      odin = libx.mkHost {
        hostname = "odin";
      };

      frigg = libx.mkHost {
        hostname = "frigg";
        pkgsInput = nixpkgs-stable;
      };

      thor = libx.mkHost {
        hostname = "thor";
      };
    };

    homeConfigurations = {
      "${username}@odin" = libx.mkHome {
        hostname = "odin";
      };

      "${username}@frigg" = libx.mkHome {
        hostname = "frigg";
      };

      "${username}@thor" = libx.mkHome {
        hostname = "thor";
      };
    };

    formatter = libx.forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays {inherit inputs;};
  };
}

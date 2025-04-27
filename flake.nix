{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "unstable";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    nix-gaming.url = "github:fufexan/nix-gaming";

    ghostty.url = "github:ghostty-org/ghostty";

    hyprland.url = "github:hyprwm/Hyprland";

    winapps = {
      url = "github:winapps-org/winapps";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    unstable,
    agenix,
    spicetify-nix,
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
        pkgs = unstable.legacyPackages.${system};
      in
        import ./pkgs {inherit pkgs;}
    );

    nixosConfigurations = {
      odin = libx.mkHost {
        hostname = "odin";
      };

      frigg = libx.mkHost {
        hostname = "frigg";
      };
    };

    homeConfigurations = {
      "${username}@odin" = libx.mkHome {
        hostname = "odin";
      };
    };

    formatter = libx.forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays {inherit inputs;};
  };
}

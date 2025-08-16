{inputs, pkgs, ...}: {
  nix.settings = {
    substituters = ["https://hyprland.cachix.org"];
    trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  };

  networking.networkmanager.enable = true;

  programs.thunar.enable = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    glibc
    zlib
  ];

  virtualisation = {
    docker.enable = true;
  };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = ''          
          ${pkgs.greetd.tuigreet}/bin/tuigreet \
            --remember \
            --remember-session \
            --asterisks \
            --time '';
        user = "greeter";
      };
    };
  };

  services.spice-vdagentd.enable = true;

  fonts.packages = with pkgs; [
    font-awesome
    monaspace
    nerd-fonts.roboto-mono
    nerd-fonts.fira-code
  ];
}
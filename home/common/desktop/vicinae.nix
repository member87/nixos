{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  # vicinae 0.29 renamed services.vicinae to programs.vicinae.
  programs.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      autoStart = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };

    settings.theme = {
      light = {
        name = "gruvbox-light";
        icon_theme = "default";
      };
      dark = {
        name = "gruvbox-dark";
        icon_theme = "default";
      };
    };

    extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
      nix
      power-profile
    ];
  };
}

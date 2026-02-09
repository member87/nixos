{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.vicinae.homeManagerModules.default
  ];

  services.vicinae = {
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
        name = "rose-pine";
        icon_theme = "default";
      };
      dark = {
        name = "rose-pine";
        icon_theme = "default";
      };
    };

    extensions = with inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}; [
      bluetooth
      nix
      power-profile
    ];
  };
}

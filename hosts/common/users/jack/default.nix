{
  pkgs,
  config,
  ...
}: let
  ifExists = groups: builtins.filter (group: builtins.hasAttr group config.users.groups) groups;
  user = "jack";
in {
  users.users.${user} = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups =
      [
        "audio"
        "users"
        "video"
        "wheel"
      ]
      ++ ifExists [
        "docker"
        "plugdev"
        "render"
        "lxd"
        "i2c"
        "kvm"
        "adbusers"
      ];

    linger = true;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSro9NaLVyjSrwgqFT1opk4Szwk08Ag7lrJoDDwhT4a"
    ];

    packages = [pkgs.home-manager];
  };

  # This is a workaround for not seemingly being able to set $EDITOR in home-manager
  environment.sessionVariables = {
    EDITOR = "nvim";
  };

  security.sudo.extraRules = [
    {
      users = ["${user}"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}

{inputs, ...}: {
  imports = [
    inputs.nixcord.homeModules.nixcord
  ];

  programs.nixcord = {
    enable = true;

    discord.vencord.enable = true; # Standard Vencord

    config = {
      themeLinks = [
        "https://raw.githubusercontent.com/shvedes/discord-gruvbox/main/gruvbox-dark.theme.css"
      ];
      enabledThemeLinks = [
        "https://raw.githubusercontent.com/shvedes/discord-gruvbox/main/gruvbox-dark.theme.css"
      ];
      frameless = true;

      plugins = {
        hideMedia.enable = true;
        messageLogger.enable = true;
        callTimer.enable = true;
        shikiCodeblocks.enable = true;
        sortFriendRequests.enable = true;
        fakeNitro.enable = true;
      };
    };
  };
}

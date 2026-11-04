{inputs, ...}: {
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser = {
    enable = true;
    policies = {
      AutoLaunchProtocolsFromOrigins = [
        {
          protocol = "spotify";
          allowed_origins = [
            "https://open.spotify.com"
            "https://spotify.link"
          ];
        }
      ];
    };
    # AutoLaunchProtocolsFromOrigins above lets Spotify's pages open spotify:// without a
    # prompt; these prefs hand the scheme to the system handler.
    extraPrefs = ''
      pref("network.protocol-handler.expose.spotify", false);
      pref("network.protocol-handler.external.spotify", true);
      pref("network.protocol-handler.warn-external.spotify", false);
    '';
  };
}

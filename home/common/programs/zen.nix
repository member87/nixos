{
  inputs,
  pkgs,
  ...
}:
{
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
    extraPrefs = ''
      // When encountering spotify:// URIs, hand off to the system handler
      // without prompting the user
      pref("network.protocol-handler.expose.spotify", false);
      pref("network.protocol-handler.external.spotify", true);
      pref("network.protocol-handler.warn-external.spotify", false);
      // Allow content-initiated external protocol launches (e.g. JS redirects)
      pref("security.external_protocol_requires_permission", false);
    '';
  };
}

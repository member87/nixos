{username, ...}: {
  # the client ID of the Spotify app the bar's music drawer signs in with;
  # read by bar-spotify (home/common/desktop/quickshell)
  age.secrets.spotify-client-id = {
    file = ../../../secrets/spotify_client_id.age;
    owner = username;
  };
}

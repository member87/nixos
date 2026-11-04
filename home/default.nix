# Home Manager config for every host; hosts/default.nix loads it through the NixOS module,
# which also sets home.username and home.homeDirectory and supplies pkgs.
{
  config,
  lib,
  pkgs,
  stateVersion,
  ...
}: {
  imports = [
    ./common
  ];

  home = {
    inherit stateVersion;

    sessionPath = [
      "${config.home.homeDirectory}/.local/share/pnpm"
      # `make -C META/zw install` symlinks zw here
      "${config.home.homeDirectory}/bin"
    ];
  };

  # Migration from standalone Home Manager, which installed home.packages into the user
  # profile as home-manager-path. They now live in /etc/profiles/per-user, and the old entry
  # comes earlier on PATH, so its stale binaries would shadow them. Delete this once both
  # hosts have switched.
  home.activation.removeStandaloneProfile = lib.hm.dag.entryBefore ["writeBoundary"] ''
    if ${pkgs.nix}/bin/nix profile list --json 2>/dev/null \
      | ${lib.getExe pkgs.jq} -e '.elements | has("home-manager-path")' >/dev/null; then
      run ${pkgs.nix}/bin/nix profile remove home-manager-path
    fi
  '';
}

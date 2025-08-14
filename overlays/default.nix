# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    opencode = prev.opencode.overrideAttrs (oldAttrs: rec {
      version = "0.3.17";
      src = prev.fetchFromGitHub {
        owner = "sst";
        repo = "opencode";
        tag = "v${version}";
        hash = "sha256-l/V9YHwuIPN73ieMT++enL1O5vecA9L0qBDGr8eRVxY=";
      };

      tui = prev.buildGoModule {
        pname = "opencode-tui";
        inherit version;
        src = "${src}/packages/tui";
        vendorHash = "sha256-0vf4fOk32BLF9/904W8g+5m0vpe6i6tUFRXqDHVcMIQ=";
        subPackages = ["cmd/opencode"];
        env.CGO_ENABLED = 0;
        ldflags = ["-s" "-X=main.Version=${version}"];
        installPhase = ''
          runHook preInstall
          install -Dm755 $GOPATH/bin/opencode $out/bin/tui
          runHook postInstall
        '';
      };

      node_modules = prev.stdenvNoCC.mkDerivation {
        pname = "opencode-node_modules";
        inherit version src;
        impureEnvVars = prev.lib.fetchers.proxyImpureEnvVars ++ ["GIT_PROXY_COMMAND" "SOCKS_SERVER"];
        nativeBuildInputs = [prev.bun prev.writableTmpDirAsHomeHook];
        dontConfigure = true;
        buildPhase = ''
          runHook preBuild
          export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
          bun install --filter=opencode --force --frozen-lockfile --no-progress
          runHook postBuild
        '';
        installPhase = ''
          runHook preInstall
          mkdir -p $out/node_modules
          cp -R ./node_modules $out
          runHook postInstall
        '';
        dontFixup = true;
        outputHash = "sha256-1ZxetDrrRdNNOfDOW2uMwMwpEs5S3BLF+SejWcRdtik=";
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
      };

      # 4. Re-define 'models-dev-data' with the new hash
      models-dev-data = prev.fetchurl {
        url = "https://models.dev/api.json";
        sha256 = "sha256-6fr0/updN1LaRmUAkVrYptKavrH3OjkNp6Ie3Fs9rW4=";
      };

    ghostty = prev.ghostty.overrideAttrs (oldAttrs: rec {
      preBuild = ''
        shopt -s globstar
        sed -i 's/^const xev = @import("xev");$/const xev = @import("xev").Epoll;/' **/*.zig
        shopt -u globstar
      '';
    });
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}

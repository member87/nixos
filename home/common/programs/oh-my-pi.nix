{inputs, ...}: {
  imports = [inputs.omp.homeManagerModules.default];

  programs.omp.enable = true;

  # Skills are pinned in flake.lock; update with `nix flake update skill-impeccable skill-taste`.
  home.file = {
    ".omp/agent/skills/impeccable".source = "${inputs.skill-impeccable}/.omp/skills/impeccable";
    ".omp/agent/skills/design-taste-frontend".source = "${inputs.skill-taste}/skills/taste-skill";
  };
}

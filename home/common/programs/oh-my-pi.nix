{inputs, ...}: {
  imports = [inputs.omp.homeManagerModules.default];

  programs.omp = {
    enable = true;
    settings.startup.quiet = true;
  };
}

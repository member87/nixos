{inputs, ...}: {
  imports = [inputs.omp.homeManagerModules.default];

  programs.omp.enable = true;
}

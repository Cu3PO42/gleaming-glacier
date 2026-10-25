{origin, ...}: {
  imports = [
    origin.inputs.lazyvim.homeManagerModules.default
  ];

  programs.lazyvim.enable = true;
}
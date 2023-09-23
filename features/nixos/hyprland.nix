{config, inputs, ...}: {
  imports = [
    inputs.hyprland.nixosModules.default
  ];

  programs.hyprland = {
    enable = true;
    nvidiaPatches = config.copper.feature.nvidia.enable;
  };
}

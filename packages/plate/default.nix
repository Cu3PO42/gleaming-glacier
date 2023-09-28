{
  pkgs,
  inputs,
  ...
}:
pkgs.writeShellApplication {
  name = "plate";
  runtimeInputs = with pkgs; [
    openssh
    inputs.self.outputs.packages.${pkgs.system}.op-wsl-proxy
    nixos-rebuild
    inputs.nixos-anywhere.packages.${pkgs.system}.default
    jq
    gnused
    gawk
  ];
  text = builtins.readFile ./plate.sh;
}

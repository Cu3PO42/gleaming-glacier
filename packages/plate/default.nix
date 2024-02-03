{
  pkgs,
  self,
  inputs,
  ...
}:
pkgs.writeShellApplication {
  name = "plate";
  runtimeInputs = with pkgs; [
    openssh
    self.op-wsl-proxy
    nixos-rebuild
    inputs.nixos-anywhere.packages.default
    jq
    gnused
    gawk
  ];
  text = builtins.readFile ./plate.sh;
}

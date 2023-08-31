{
  pkgs,
  inputs,
  ...
}:
pkgs.writeShellApplication {
  name = "plate";
  # TODO: consider importing nixos-anywhere via overlay
  runtimeInputs = with pkgs; [openssh _1password nixos-rebuild inputs.nixos-anywhere.packages.${pkgs.system}.default jq];
  text = builtins.readFile ./plate.sh;
}

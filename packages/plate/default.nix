{
  pkgs,
  self,
  inputs,
  lib,
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
    dos2unix
  ];
  text = builtins.readFile ./plate.sh;

  meta = with lib; {
    description = "A NixOS deployment tool with 1Password integration.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.all;
  };
}

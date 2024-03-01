{
  pkgs,
  self,
  inputs,
  lib,
  ...
}:
pkgs.writeShellApplication {
  name = "mage";
  runtimeInputs = with pkgs; [
    inputs.agenix.packages.agenix
    self.op-wsl-proxy
    dos2unix
    gnused
  ];
  text = builtins.readFile ./mage.sh;

  meta = with lib; {
    description = "A tool to make usage of Agenix that much more convenient.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.all;
  };
}

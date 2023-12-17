{pkgs, ...}:
pkgs.writeShellApplication {
  name = "chromactl";
  runtimeInputs = with pkgs; [
    jq
  ];
  text = builtins.readFile ./chromactl.sh;
}

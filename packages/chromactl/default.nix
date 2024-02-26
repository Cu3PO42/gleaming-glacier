{pkgs, lib, ...}:
pkgs.writeShellApplication {
  name = "chromactl";
  runtimeInputs = with pkgs; [
    jq
  ];
  text = builtins.readFile ./chromactl.sh;

  meta = with lib; {
    description = "The CLI for the Chroma theming system.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.all;
  };
}

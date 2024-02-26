{
  writeShellApplication,
  jq,
  swww,
  lib,
  ...
}:
writeShellApplication {
  name = "swimctl";
  runtimeInputs = [jq swww];
  text = builtins.readFile ./swimctl.sh;

  meta = with lib; {
    description = "A tool to switch wallpapers via swww.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.linux;
  };
}

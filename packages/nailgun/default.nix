{
  writeShellApplication,
  imagemagick,
  parallel,
  lib,
  ...
}:
writeShellApplication {
  name = "nailgun";
  runtimeInputs = [imagemagick parallel];
  text = builtins.readFile ./nailgun.sh;

  meta = with lib; {
    description = "A tool to genrate thumbnails from images, in particular those used by Hyprdots' Rofi launchers.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.all;
  };
}

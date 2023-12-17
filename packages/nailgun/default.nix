{
  writeShellApplication,
  imagemagick,
  parallel,
  ...
}:
writeShellApplication {
  name = "nailgun";
  runtimeInputs = [imagemagick parallel];
  text = builtins.readFile ./nailgun.sh;
}

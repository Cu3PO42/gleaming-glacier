{
  writeShellApplication,
  jq,
  swww,
  ...
}:
writeShellApplication {
  name = "swimctl";
  runtimeInputs = [jq swww];
  text = builtins.readFile ./swimctl.sh;
}

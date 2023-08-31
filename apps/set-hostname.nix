{writeShellApplication, ...}:
writeShellApplication {
  name = "set-hostname";
  text = builtins.readFile ../scripts/set-hostname.sh;
}

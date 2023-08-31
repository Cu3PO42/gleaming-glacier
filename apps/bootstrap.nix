{writeShellApplication, ...}:
writeShellApplication {
  name = "bootstrap";
  text = builtins.readFile ../scripts/bootstrap.sh;
}

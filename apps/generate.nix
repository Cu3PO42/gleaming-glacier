{writeShellApplication, ...}:
writeShellApplication {
  name = "generate";
  text = builtins.readFile ../scripts/generate.sh;
}

{
  runCommand,
  bash,
  git,
  age,
  agenix,
}:
runCommand "mage-integration-tests" {
  nativeBuildInputs = [bash git age agenix];
  MAGE_SCRIPT = ../packages/mage/mage.sh;
} ''
  bash ${./test_mage.sh}
  touch "$out"
''

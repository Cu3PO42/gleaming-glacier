{...}: {
  startsWith = prefix: str: builtins.substring 0 (builtins.stringLength prefix) str == prefix;
}
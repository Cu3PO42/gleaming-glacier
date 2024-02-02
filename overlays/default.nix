{
  inputs,
  outputs,
}: {
  themes = final: prev: {chromaThemes = import ../themes {pkgs = final;};};
}

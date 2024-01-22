{lib, ...}: with lib; {
  colorType = types.str // {
    check = s: types.str.check s && (builtins.match "^[0-9a-fA-F]{6}$" s != null);
  };

}
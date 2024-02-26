{writeShellApplication, lib, ...}: (writeShellApplication {
  name = "spacectl";
  text = builtins.readFile ./spacectl.sh;
}).overrideAttrs (old: {
  meta = (old.meta or {}) // {
    platforms = lib.platforms.darwin;
  };
})
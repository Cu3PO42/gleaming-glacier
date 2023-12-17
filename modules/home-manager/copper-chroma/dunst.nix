{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    copper.chroma.dunst.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to enable Dunst theming as part of Chroma.
      '';
    };
  };

  config = {
    copper.chroma.programs.dunst = {
      templates."dunstrc" = {
        name,
        opts,
      }: let
        gtkOpts = config.copper.chroma.finalThemes.${name}.gtk;
      in ''
        [global]
            ### Icons ###

            # Recursive icon lookup. You can set a single theme, instead of having to
            # define all lookup paths.
            enable_recursive_icon_lookup = true

            # Set icon theme (only used for recursive icon lookup)
            # You can also set multiple icon themes, with the leftmost one being used first.
            icon_theme = ${gtkOpts.iconTheme.name}
      '';
    };
  };

  imports = [
    (mkIf (config.copper.chroma.enable && config.copper.chroma.dunst.enable) {
      xdg.configFile."dunst/dunstrc.d/50-chroma".source = config.lib.file.mkOutOfStoreSymlink "${config.copper.chroma.themeFolder}/active/dunst/dunstrc";
    })
  ];
}

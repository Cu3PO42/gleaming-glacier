{config, lib, self, inputs, flake-parts-lib, ...}: with lib; flake-parts-lib.mkTransposedPerSystemModule {
  name = "chromaThemes";
  file = ./copper-chroma.nix;
  option = mkOption {
    type = (evalModules {
      # TODO: all module imports in this file must refer to root flake, not really self
      modules = [
        self.homeModules.copper-chroma
        { _module.check = false; }
      ];
      # TODO: we currently can't includee these modules because they refer to other home-manager modules, which aren't included above; maybe use fulll HM config, but make the check optional?
      # ++ config.copper.chroma.modules;
    }).options.copper.chroma.themes.type;
    default = {};
    description = ''
      A set of themes for the Chroma theming system.
    '';
  };
} // {
  imports = [{
    options = {
      copper.chroma.modules = mkOption {
        type = with types; listOf deferredModule;
        description = ''
          A list of Home-Manager modules that provide Chroma integrations for
          various applications. These influence only the type checking of the
          `chromaThemes` Flake option.
        '';
      };
    };

    config = {
      copper.chroma.modules = lib.mkDefault (map ({value, ...}: value) (filter ({name, value}: self.lib.startsWith "copper-chroma/" name) (attrsToList self.homeModules)));
    };
  }];
}
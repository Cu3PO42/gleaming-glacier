{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.programs.lunarvim;

  pluginWithConfigType = types.submodule {
    options = {
      config = mkOption {
        type = types.nullOr types.lines;
        description = "Script to configure this plugin. The scripting language should match type.";
        default = null;
      };

      type = mkOption {
        type =
          types.either (types.enum ["lua" "viml" "teal" "fennel"]) types.str;
        description = "Language used in config. Configurations are aggregated per-language.";
        default = "viml";
      };

      optional =
        mkEnableOption "optional"
        // {
          description = "Don't load by default (load with :packadd)";
        };

      plugin = mkOption {
        type = types.package;
        description = "vim plugin";
      };
    };
  };

  luaPackages = cfg.finalPackage.unwrapped.lua.pkgs;
  resolvedExtraLuaPackages = cfg.extraLuaPackages luaPackages;

  extraMakeWrapperArgs = ''--suffix PATH : "${lib.makeBinPath (with pkgs; [git ripgrep fd (tree-sitter.withPlugins builtins.attrValues)] ++ cfg.extraPackages)}"'';
  extraMakeWrapperLuaCArgs = lib.optionalString (resolvedExtraLuaPackages != []) ''
    --suffix LUA_CPATH ";" "${
      lib.concatMapStringsSep ";" luaPackages.getLuaCPath
      resolvedExtraLuaPackages
    }"'';
  extraMakeWrapperLuaArgs =
    lib.optionalString (resolvedExtraLuaPackages != [])
    ''
      --suffix LUA_PATH ";" "${
        lib.concatMapStringsSep ";" luaPackages.getLuaPath
        resolvedExtraLuaPackages
      }"'';

  lunarvimBaseDir = cfg.lvimSrc;
  lunarvimConfigDir = "${config.xdg.configHome}/lvim";
  extraMakeWrapperLunarVimArgs = let
    inherit (config) xdg;
  in
    ''--set LUNARVIM_RUNTIME_DIR "${xdg.dataHome}/lunarvim" ''
    + ''--set LUNARVIM_CONFIG_DIR "${lunarvimConfigDir}" ''
    + ''--set LUNARVIM_CACHE_DIR "${xdg.cacheHome}/lvim" ''
    + ''--set LUNARVIM_BASE_DIR "${lunarvimBaseDir}" ''
    + ''--add-flags '-u "${lunarvimBaseDir}/init.lua"' '';

  src = pkgs.fetchFromGitHub {
    owner = "LunarVim";
    repo = "LunarVim";
    rev = "d663929036e23bd54427cf3e78dedf5b34ab97fc";
    hash = "sha256-6JbMx0jRqzQb/NjhoC19jc6FCT/aNhqEFWjzP0v8K/Y=";
  };
in {
  options = {
    programs.lunarvim = {
      enable = mkEnableOption "LunarVim";

      vimdiffAlias = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Alias {command}`vimdiff` to {command}`lvim -d`.
        '';
      };

      extraPython3Packages = mkOption {
        # In case we get a plain list, we need to turn it into a function,
        # as expected by the function in nixpkgs.
        # The only way to do so is to call `const`, which will ignore its input.
        type = with types; functionTo (listOf package);
        default = _: [];
        defaultText = literalExpression "ps: [ ]";
        example =
          literalExpression "pyPkgs: with pyPkgs; [ python-language-server ]";
        description = ''
          The extra Python 3 packages required for your plugins to work.
          This option accepts a function that takes a Python 3 package set as an argument,
          and selects the required Python 3 packages from this package set.
          See the example for more info.
        '';
      };

      # We get the Lua package from the final package and use its
      # Lua packageset to evaluate the function that this option was set to.
      # This ensures that we always use the same Lua version as the Neovim package.
      extraLuaPackages = mkOption {
        type = with types; functionTo (listOf package);
        default = _: [];
        defaultText = literalExpression "ps: [ ]";
        example = literalExpression "luaPkgs: with luaPkgs; [ luautf8 ]";
        description = ''
          The extra Lua packages required for your plugins to work.
          This option accepts a function that takes a Lua package set as an argument,
          and selects the required Lua packages from this package set.
          See the example for more info.
        '';
      };

      config = mkOption {
        type = options.home.file.type.nestedTypes.elemType;
        default.source = "${cfg.lvimSrc}/utils/installer/config.example.lua";
        example = literalExpression "{ source = ./config.lua }";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.neovim-unwrapped;
        defaultText = literalExpression "pkgs.neovim-unwrapped";
        description = "The package to use for the neovim binary.";
      };

      lvimSrc = mkOption {
        type = types.path;
        default = src;
        description = "The LunarVim repository we want to install.";
      };

      finalPackage = mkOption {
        type = types.package;
        visible = false;
        readOnly = true;
        description = "Resulting customized neovim package.";
      };

      defaultEditor = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to configure {command}`lvim` as the default
          editor using the {env}`EDITOR` environment variable.
        '';
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        default = [];
        example = literalExpression "[ pkgs.shfmt ]";
        description = "Extra packages available to nvim.";
      };
    };
  };

  config = let
    neovimConfig = pkgs.neovimUtils.makeNeovimConfig {
      inherit (cfg) extraPython3Packages;
      withRuby = true;
      extraName = "-lunarvim";
      vimAlias = false;
      viAlias = false;
      withPython3 = true;
      withNodeJs = true;
      plugins = [];
    };
  in mkIf cfg.enable {
    home.packages = [cfg.finalPackage];

    home.sessionVariables = mkIf cfg.defaultEditor {EDITOR = "lvim";};

    home.file."${lunarvimConfigDir}/config.lua" = cfg.config;

    programs.lunarvim.finalPackage = let
      wrappedNeovim =
        pkgs.wrapNeovimUnstable cfg.package
        (neovimConfig
          // {
            wrapperArgs =
              (lib.escapeShellArgs neovimConfig.wrapperArgs)
              + " "
              + extraMakeWrapperArgs
              + " "
              + extraMakeWrapperLuaCArgs
              + " "
              + extraMakeWrapperLuaArgs
              + " "
              + extraMakeWrapperLunarVimArgs;
            wrapRc = false;
          });
    in
      pkgs.symlinkJoin {
        name = "lunarvim";
        paths = [wrappedNeovim];
        postBuild = "mv $out/bin/nvim $out/bin/lvim";
      };

    programs.bash.shellAliases = mkIf cfg.vimdiffAlias {vimdiff = "lvim -d";};
    programs.fish.shellAliases = mkIf cfg.vimdiffAlias {vimdiff = "lvim -d";};
    programs.zsh.shellAliases = mkIf cfg.vimdiffAlias {vimdiff = "lvim -d";};

    home.activation.lunarvimInit = lib.hm.dag.entryAfter ["writeBoundary"] "
      ${cfg.finalPackage}/bin/lvim --headless -c 'quitall'

      if ! PATH=\"${cfg.finalPackage}/bin\":$PATH bash '${lunarvimBaseDir}/utils/ci/verify_plugins.sh'; then
        echo '[LunarVim]: Unable to verify plugins, make sure to manually run \":Lazy sync\" when starting lvim for the first time.'
      fi
    ";
  };
}

{config, lib, pkgs, ...}: with lib; let
  cfg = config.copper.chroma;
in {
  options = {
    copper.chroma.wezterm.enable = mkOption {
      type = types.bool;
      default = config.programs.wezterm.enable;
      example = false;
      description = ''
        Whetehr to enable Wezterm theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.wezterm.enable) || config.programs.wezterm.enable;
        message = ''
          Chroma Wezterm theming requires Wezterm to be enabled.
        '';
      }
    ];

    copper.chroma.programs.wezterm = {
      themeOptions = {
        name = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "Catppuccin Mocha";
          description = ''
            The name of the theme to use for Wezterm. Currently, only built-in
            themes are supported.
          '';
        };

      };

      themeConfig = {config, opts, ...}: {
        file."theme.lua".text = ''
          return ${generators.toLua {} {
            color_scheme = config.name;
            xcursor_theme = opts.desktop.cursorTheme.name;
          }}
        '';
      };

      reloadCommand = ''
        ${pkgs.coreutils}/bin/touch ${config.xdg.configHome}/wezterm/chroma-reload-trigger.lue
      '';
    };

    programs.wezterm.structuredConfig.chroma = mkIf (cfg.enable && cfg.wezterm.enable) (hm.dag.entryAnywhere ''
      package.path = package.path .. ';${cfg.themeDirectory}/active/wezterm/?.lua'
      apply(require "theme")

      -- This code is only to send config reload events to Wezterm. The file
      -- will always be empty.
      local configHome = os.getenv("XDG_CONFIG_HOME") or os.getenv("HOME") .. "/.config"
      local filePath = configHome .. "/wezterm/chroma-reload-trigger.lua"

      local file = io.open(filePath, "r")
      if not file then
          file = io.open(filePath, "w")
          if file then
              file:close()
          end
      else
          file:close()
      end

      require "chroma-reload-trigger"
    '');
  };
}
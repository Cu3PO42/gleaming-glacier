{config, lib, ...}: with lib; let
  cfg = config.programs.wezterm;
in {
  options = {
    programs.wezterm = {
      enableStructuredConfig = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable structured configuration for wezterm. This replaces the
          standard extraConfig option with a DAG of configurations.
        '';
      };

      structuredConfig = mkOption {
        type = hm.types.dagOf types.str;
        default = {};
        description = ''
          A DAG of configuration lines for Wezterm. You have access to a
          variable `config` that you can write your options to. Additionally,
          an `apply` function is available to merge a table into the config.
        '';
      };
    };
  };

  config = {
    programs.wezterm.extraConfig = mkIf cfg.enableStructuredConfig (let
      sortedConfig = hm.dag.topoSort cfg.structuredConfig;
      config = if sortedConfig ? result then
        concatMapStringsSep "\n" (res: res.data) sortedConfig.result
      else
        abort ("Dependency cycle detected in wezterm configuration: " + builtins.toJSON sortedConfig);
    in ''
      local config = wezterm.config_builder()
      function apply (c)
        for k, v in pairs(c) do
          config[k] = v
        end
      end

      ${config}

      return config
    '');
  };
}
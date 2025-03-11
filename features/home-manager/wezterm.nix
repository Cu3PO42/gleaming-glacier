{config, lib, pkgs, copper, ...}: {
  programs.wezterm = {
    enable = true;

    enableStructuredConfig = true;
    structuredConfig.base = lib.hm.dag.entryAnywhere ''
      package.path = package.path .. ';${config.xdg.configHome}/wezterm/mine/?;${config.xdg.configHome}/wezterm/mine/?.lua'

      apply(require "mine/wezterm")
    '';
  };
  copper.file.config."wezterm/mine" = "config/wezterm";
}

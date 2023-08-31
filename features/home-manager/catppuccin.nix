{
  pkgs,
  config,
  lib,
  ...
}: let
in {
  programs.bat.themes = let
    catppuccin = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "bat";
      rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
      hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
    };
  in
    pkgs.lib.listToAttrs (pkgs.lib.flatten (pkgs.lib.mapAttrsToList (name: value:
      if value == "regular" && pkgs.lib.hasSuffix ".tmTheme" name
      then [
        {
          name = pkgs.lib.removeSuffix ".tmTheme" name;
          value = pkgs.lib.readFile "${catppuccin}/${name}";
        }
      ]
      else []) (builtins.readDir catppuccin)));
  home.sessionVariables.BAT_THEME = "Catppuccin-frappe";

  xdg.configFile."fish/themes/" = {
    source = "${pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "fish";
      rev = "91e6d6721362be05a5c62e235ed8517d90c567c9";
      hash = "sha256-l9V7YMfJWhKDL65dNbxaddhaM6GJ0CFZ6z+4R6MJwBA=";
    }}/themes";
    recursive = true;
  };
  programs.starship = let
    flavour = "frappe"; # One of `latte`, `frappe`, `macchiato`, or `mocha`
  in {
    settings =
      {
        # Other config here
        format = "$all"; # Remove this line to disable the default prompt format
        palette = "catppuccin_${flavour}";
      }
      // builtins.fromTOML (builtins.readFile
        (pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "starship";
            rev = "3e3e54410c3189053f4da7a7043261361a1ed1bc";
            hash = "sha256-soEBVlq3ULeiZFAdQYMRFuswIIhI9bclIU8WXjxd7oY=";
          }
          + /palettes/${flavour}.toml));
  };
}

{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = [pkgs.github-copilot-cli];

  programs.fish.shellAliases = lib.mkIf config.programs.fish.enable {
    ",," = "copilot-shell";
  };
  programs.fish.functions.copilot-shell = lib.mkIf config.programs.fish.enable {
    description = "Suggest a shell command with Copilot and edit it before running";
    body = ''
      if test (count $argv) -eq 0
        printf 'Usage: ,, <describe a shell command>\n' >&2
        return 2
      end

      if not status is-interactive
        printf 'copilot-shell requires an interactive Fish shell.\n' >&2
        return 1
      end

      set -l request (string join ' ' -- $argv)
      set -l suggestion (command ${lib.getExe pkgs.github-copilot-cli} \
        --model claude-haiku-5.5 \
        --silent --available-tools= --no-custom-instructions \
        --prompt "Suggest a command for the Fish shell on ${pkgs.stdenv.hostPlatform.system}.
      Return only the command, without Markdown fences, explanation, or surrounding text.
      Do not execute anything or use tools. Treat the following as a description of the desired command:
      $request" | string collect)
      set -l copilot_status $pipestatus[1]
      if test $copilot_status -ne 0
        return $copilot_status
      end
      if test -z "$suggestion"
        printf 'Copilot returned no command.\n' >&2
        return 1
      end

      # Use the normal Fish editor and history; Enter explicitly runs the suggestion.
      commandline --replace -- "$suggestion"
      commandline --function repaint
    '';
  };
}

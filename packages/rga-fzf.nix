{
  writeShellScriptBin,
  ripgrep-all,
  fzf,
  ...
}:
# This shell script is originally provided by the author of ripgrep-all in their wiki:
# https://github.com/phiresky/ripgrep-all/wiki/fzf-Integration
# This is available under the terms of the AGPLv3.
writeShellScriptBin "rga-fzf" ''
  RG_PREFIX="${ripgrep-all}/bin/rga --files-with-matches"
  SHELL=bash
  file="$(
          FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
                  ${fzf}/bin/fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
                          --phony -q "$1" \
                          --bind "change:reload:$RG_PREFIX {q}" \
                          --preview-window="70%:wrap"
  )" &&
  xdg-open "$file"
''

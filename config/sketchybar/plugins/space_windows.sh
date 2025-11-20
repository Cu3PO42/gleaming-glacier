#!/bin/bash

echo "in space windows change from: $SENDER"

if [ "$SENDER" = "space_windows_change" ]; then
  args=(--animate sin 10)

  if [ "$SKETCHYBAR_WM" == "yabai" ]; then
    space="$(echo "$INFO" | jq -r '.space')"

    apps=$(
      yabai -m query --windows --space $space |
      jq -r "map(select(  (.[\"is-minimized\"] == false) and ((.app != \"Microsoft Teams classic\") or (.level != 3))  )) | [.[].app] | unique | .[]"
    )
  elif [ "$SKETCHYBAR_WM" == "aerospace" ]; then
    echo "Handling for aerospace"
    apps=$(
      aerospace list-windows --workspace $SPACE --json | jq -r ".[] | .[\"app-name\"]"
    )
    echo "Apps on space $SPACE: ${apps}"
  fi

  icon_strip=" "
  if [ "${apps}" != "" ]; then
    while read -r app
    do
      icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
    done <<< "${apps}"
  fi
  args+=(--set space.$space label="$icon_strip")

  sketchybar -m "${args[@]}"
fi
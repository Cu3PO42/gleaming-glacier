#!/bin/bash

# Load colors (to get HIGHLIHGT_COLOR and others)
source "$CONFIG_DIR/colors.sh"

# If FOCUSED_WORKSPACE is not set (e.g. from front_app_switched), fetch it
if [ -z "$FOCUSED_WORKSPACE" ]; then
  FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
fi

# Highlighting
if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
  sketchybar --set $NAME background.drawing=on \
                         background.color=$BACKGROUND_2 \
                         label.color=$WHITE \
                         icon.color=$WHITE \
                         icon.highlight=on \
                         label.highlight=on
else
  sketchybar --set $NAME background.drawing=off \
                         label.color=$GREY \
                         icon.color=$GREY \
                         icon.highlight=off \
                         label.highlight=off
fi

# Get apps in the workspace
# Use --workspace $1 to make sure we are querying the workspace this item represents
apps=$(aerospace list-windows --workspace "$1" --json | jq -r '.[]."app-name"' | sort | uniq)

icon_strip=""
if [ "${apps}" != "" ] && [ "${apps}" != "null" ]; then
  while read -r app
  do
    icon_strip+=" $($CONFIG_DIR/plugins/icon_map.sh "$app")"
  done <<< "${apps}"
fi

# Set the icon strip (apps) as label
# If empty, we still update it to clear it
if [ "$icon_strip" != "" ]; then
  sketchybar --set $NAME label="$icon_strip" label.drawing=on
else
  sketchybar --set $NAME label.drawing=off
fi

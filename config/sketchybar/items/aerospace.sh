#!/bin/bash

sketchybar --add event aerospace_workspace_change

# This script is called by sketchybarrc to initialize the workspaces
# and also by the aerospace_workspace_change event to sync new workspaces

# Function to add a workspace item
add_workspace_item() {
  local sid=$1
  local monitor_id=$2
  
  sketchybar --add item space.$sid left \
    --subscribe space.$sid aerospace_workspace_change front_app_switched space_windows_change \
    --set space.$sid \
    background.color=$BACKGROUND_1 \
    background.border_color=$BACKGROUND_2 \
    background.drawing=off \
    icon="$sid" \
    click_script="aerospace workspace $sid" \
    script="$PLUGIN_DIR/aerospace.sh $sid" \
    padding_left=0 \
    padding_right=0 \
    icon.padding_left=10 \
    icon.padding_right=0 \
    label.padding_right=20 \
    icon.highlight_color=$HIGHLIHGT_COLOR \
    icon.color=$GREY \
    label.color=$GREY \
    label.highlight_color=$HIGHLIHGT_COLOR \
    label.font="sketchybar-app-font:Regular:16.0" \
    label.y_offset=-1 \
    label.drawing=off \
    associated_display=$monitor_id
}

# Sync workspaces from aerospace
sync_workspaces() {
  # Get all workspaces and their monitor IDs
  aerospace list-workspaces --all --format '%{workspace} %{monitor-id}' | while read -r sid monitor_id; do
    # Only add if it doesn't exist yet
    if ! sketchybar --query item space.$sid > /dev/null 2>&1; then
      add_workspace_item "$sid" "$monitor_id"
    fi
  done
}

# Initial sync
sync_workspaces

# Add an updater item to handle dynamic workspace creation
sketchybar --add item workspace_updater left \
           --set workspace_updater \
                drawing=off \
                script="$ITEM_DIR/aerospace.sh sync" \
           --subscribe workspace_updater aerospace_workspace_change

# If called as "sync", just run the sync
if [ "$1" = "sync" ]; then
  sync_workspaces
fi

# Ensure bracket is updated
sketchybar --add bracket spaces_bracket '/space\..*/'  \
           --set spaces_bracket "${bracket_defaults[@]}"
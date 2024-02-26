#!/bin/bash

battery=(
  script="$PLUGIN_DIR/battery.sh"
  icon.font="$FONT:Regular:19.0"
  icon.padding_left=$(($PADDINGS * 2))
  icon.padding_right=0
  label.padding_left=0
  label.padding_right=0
  label.drawing=off
  icon.drawing=off
  update_freq=120
  updates=on
)

sketchybar --add item battery right      \
           --set battery "${battery[@]}" \
           --subscribe battery power_source_change system_woke

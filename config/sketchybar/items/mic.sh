#!/bin/bash
sketchybar --add item mic right \
sketchybar --set mic update_freq=3 \
           --set mic script="$PLUGIN_DIR/mic.sh" \
           --set mic click_script="$PLUGIN_DIR/mic_click.sh"
           
MIC_VOLUME=$(osascript -e 'input volume of (get volume settings)')

if [[ $MIC_VOLUME -eq 0 ]]; then
  sketchybar -m --set mic icon=􀊲
elif [[ $MIC_VOLUME -gt 0 ]]; then
  sketchybar -m --set mic icon=􀊰
fi
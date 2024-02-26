#!/bin/bash

update() {
  source "$CONFIG_DIR/colors.sh"
  COLOR=$BACKGROUND_2
  if [ "$SELECTED" = "true" ]; then
    COLOR=$GREY
  fi
  sketchybar --set $NAME icon.highlight=$SELECTED \
                         label.highlight=$SELECTED \
                         background.border_color=$COLOR
}

mouse_clicked() {
  if [ "$BUTTON" = "right" ]; then
    # Disabled because I disabled the yabai extensio
    #yabai -m space --destroy $SID
    #sketchybar --trigger windows_on_spaces --trigger space_change
    :
  else
    spacectl switch $SID
  fi
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac

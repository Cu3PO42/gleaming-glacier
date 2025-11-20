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
  if [ $SKETCHYBAR_WM == "yabai" ]; then
    if [ "$BUTTON" = "right" ]; then
      # Disabled because I disabled the yabai extensio
      #yabai -m space --destroy $SID
      #sketchybar --trigger windows_on_spaces --trigger space_change
      :
    else
      spacectl switch $SID
    fi
  elif [ $SKETCHYBAR_WM == "aerospace" ]; then
    if [ "$BUTTON" = "right" ]; then
    else
      aerospace workspace $SID
    fi
  fi
}

case "$SENDER" in
  "mouse.clicked") mouse_clicked
  ;;
  *) update
  ;;
esac

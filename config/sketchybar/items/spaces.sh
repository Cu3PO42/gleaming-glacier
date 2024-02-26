#!/bin/bash

SPACE_ICONS=("1" "2" "3" "4" "5" "6" "7" "8" "9" "10" "11" "12" "13" "14" "15" "16" "17" "18" "19" "20" "21" "22" "23" "24")

sid=0
spaces=()
for i in "${!SPACE_ICONS[@]}"
do
  sid=$(($i+1))

  space=(
    space=$sid
    icon="${SPACE_ICONS[i]}"
    icon.padding_left=10
    icon.padding_right=0
    padding_left=0
    padding_right=0
    label.padding_right=20
    icon.highlight_color=$HIGHLIHGT_COLOR
    label.color=$GREY
    label.highlight_color=$HIGHLIHGT_COLOR
    label.font="sketchybar-app-font:Regular:16.0"
    label.y_offset=-1
    background.color=$BACKGROUND_1
    background.border_color=$BACKGROUND_2
    background.drawing=off
    script="$PLUGIN_DIR/space.sh"
  )

  sketchybar --add space space.$sid left    \
             --set space.$sid "${space[@]}" \
             --subscribe space.$sid mouse.clicked
done

spaces_bracket=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
)

updater=(
  label.drawing=off
  icon.drawing=off
  background.drawing=off
  script="$PLUGIN_DIR/space_windows.sh"
)

sketchybar --add bracket spaces_bracket '/space\..*/'  \
           --set spaces_bracket "${bracket_defaults[@]}" \
           --add item space_updater left \
           --set space_updater "${updater[@]}" \
           --subscribe space_updater space_windows_change


#!/bin/bash
POPUP_CLICK_SCRIPT="sketchybar --set ical popup.drawing=toggle"

# TODO: update the color here
sketchybar --add       item            ical right                         \
           --set       ical            update_freq=180                    \
                                       icon=􀉉                             \
                                       icon.color=${HIGHLIHGT_COLOR}               \
                                       label.color=${HIGHLIHGT_COLOR}              \
                                       popup.align=right                  \
                                       script="$PLUGIN_DIR/ical.sh"       \
                                       click_script="$POPUP_CLICK_SCRIPT" \
                                       padding_right=0                    \
                                       padding_left=$GROUP_PADDING                    \
           --subscribe ical            mouse.clicked                      \
                                       mouse.entered                      \
                                       mouse.exited                       \
                                       mouse.exited.global                \
                                                                          \
           --add       item            ical.template popup.ical           \
           --set       ical.template   drawing=off                        \
                                       background.corner_radius=12        \
                                       padding_left=7                     \
                                       padding_right=7                    \
                                       icon.background.height=2           \
                                       icon.background.y_offset=-12
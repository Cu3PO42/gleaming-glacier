APPLE_MUSIC_EVENT="com.apple.Music.playerInfo"
POPUP_SCRIPT="sketchybar -m --set applemusic.anchor popup.drawing=toggle"

sketchybar --add       event           applemusic_change $APPLE_MUSIC_EVENT     \
           --add       item            applemusic.anchor e .                    \
           --set       applemusic.anchor  script="$PLUGIN_DIR/applemusic.sh"    \
                                       click_script="$POPUP_SCRIPT"             \
                                       popup.horizontal=on                      \
                                       popup.align=center                       \
                                       popup.height=120                         \
                                       icon=                                   \
                                       icon.font="$NERD_FONT:Regular:16.0"           \
                                       padding_left=10 padding_right=10        \
                                       label.drawing=off                        \
                                       drawing=on                               \
                                       y_offset=0                               \
           --subscribe applemusic.anchor  mouse.entered mouse.exited            \
                                       mouse.exited.global                      \
                                                                                \
           --add       item            applemusic.cover popup.applemusic.anchor \
           --set       applemusic.cover   script="$PLUGIN_DIR/applemusic.sh"    \
                                       label.drawing=off                        \
                                       icon.drawing=off                         \
                                       background.padding_left=12               \
                                       background.padding_right=10              \
                                       background.image.scale=0.15              \
                                       background.image.drawing=on              \
                                       background.drawing=on                    \
                                                                                \
           --add       item            applemusic.title popup.applemusic.anchor \
           --set       applemusic.title   icon.drawing=off                      \
                                       background.padding_left=0                \
                                       background.padding_right=0               \
                                       width=0                                  \
                                       label.font="$FONT:Heavy:14.0"            \
                                       y_offset=40                              \
                                                                                \
           --add       item            applemusic.artist popup.applemusic.anchor\
           --set       applemusic.artist  icon.drawing=off                      \
                                       y_offset=20                              \
                                       background.padding_left=0                \
                                       background.padding_right=0               \
                                       width=0                                  \
                                                                                \
           --add       item            applemusic.album popup.applemusic.anchor \
           --set       applemusic.album   icon.drawing=off                      \
                                       background.padding_left=0                \
                                       background.padding_right=0               \
                                       y_offset=3                               \
                                       width=0                                  \
                                                                                \
           --add       item            applemusic.shuffle popup.applemusic.anchor\
           --set       applemusic.shuffle icon=􀊝                                \
                                       icon.padding_left=5                      \
                                       icon.padding_right=5                     \
                                       icon.color=$BLACK                        \
                                       icon.highlight_color=$MAGENTA            \
                                       label.drawing=off                        \
                                       script="$PLUGIN_DIR/applemusic.sh"       \
                                       y_offset=-30                             \
           --subscribe applemusic.shuffle mouse.clicked                         \
                                                                                \
           --add       item            applemusic.back popup.applemusic.anchor  \
           --set       applemusic.back    icon=􀊎                                \
                                       icon.padding_left=5                      \
                                       icon.padding_right=5                     \
                                       icon.color=$BLACK                        \
                                       script="$PLUGIN_DIR/applemusic.sh"       \
                                       label.drawing=off                        \
                                       y_offset=-30                             \
           --subscribe applemusic.back    mouse.clicked                         \
                                                                                \
           --add       item            applemusic.play popup.applemusic.anchor  \
           --set       applemusic.play    icon=􀊔                                \
                                       background.height=40                     \
                                       background.corner_radius=20              \
                                       width=40                                 \
                                       align=center                             \
                                       background.color=$BLACK                  \
                                       background.border_color=$WHITE           \
                                       background.border_width=0                \
                                       background.drawing=on                    \
                                       icon.padding_left=4                      \
                                       icon.padding_right=5                     \
                                       icon.color=$WHITE                        \
                                       updates=on                               \
                                       label.drawing=off                        \
                                       script="$PLUGIN_DIR/applemusic.sh"       \
                                       y_offset=-30                             \
           --subscribe applemusic.play    mouse.clicked applemusic_change       \
                                                                                \
           --add       item            applemusic.next popup.applemusic.anchor  \
           --set       applemusic.next    icon=􀊐                                \
                                       icon.padding_left=5                      \
                                       icon.padding_right=10                    \
                                       icon.color=$BLACK                        \
                                       label.drawing=off                        \
                                       script="$PLUGIN_DIR/applemusic.sh"       \
                                       y_offset=-30                             \
           --subscribe applemusic.next    mouse.clicked                         \
                                                                                \
           --add       item            applemusic.repeat popup.applemusic.anchor\
           --set       applemusic.repeat  icon=􀊞                                \
                                       icon.highlight_color=$MAGENTA            \
                                       icon.padding_left=5                      \
                                       icon.padding_right=10                    \
                                       icon.color=$BLACK                        \
                                       label.drawing=off                        \
                                       script="$PLUGIN_DIR/applemusic.sh"       \
                                       y_offset=-30                             \
           --subscribe applemusic.repeat  mouse.clicked                         \
                                                                                \
           --add       item            applemusic.spacer popup.applemusic.anchor\
           --set       applemusic.spacer  width=5                               \
                                                                                \
           --add      bracket          applemusic applemusic.shuffle            \
                                               applemusic.back                  \
                                               applemusic.play                  \
                                               applemusic.next                  \
                                               applemusic.repeat                \
           --set      applemusic          background.color=$MUSIC_RED           \
                                       background.corner_radius=11              \
                                       background.drawing=on                    \
                                       y_offset=-30                             \
                                       drawing=off
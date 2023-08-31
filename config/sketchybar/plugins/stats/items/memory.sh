#!/usr/bin/env bash

source "$HOME/.config/sketchybar/colors.sh"

memory=(
	background.padding_left=0
	label.font="$FONT:Heavy:12"
	#label.color="$LABEL_COLOR"
	icon="$MEMORY"
	icon.font="Font Awesome 6 Free:Solid:16.0"
	icon.color="$GREEN"
	update_freq=15
	script="$PLUGIN_DIR/stats/scripts/ram.sh"
)

sketchybar --add item memory right \
	--set memory "${memory[@]}"

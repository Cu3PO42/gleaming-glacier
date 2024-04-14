#!/usr/bin/env sh

# set variables
RofiConf="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/themeselect.rasi"
SWIM_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/swim"


# scale for monitor x res
x_monres=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
monitor_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')
x_monres=$(( x_monres * 17 / monitor_scale ))


# set rofi override
hypr_border=`hyprctl -j getoption decoration:rounding | jq '.int'`
elem_border=$(( hypr_border * 3 ))
r_override="element{border-radius:${elem_border}px;} listview{columns:6;spacing:100px;} element{padding:0px;orientation:vertical;} element-icon{size:${x_monres}px;border-radius:0px;} element-text{padding:20px;}"

WALLPAPER_DIR=$(jq -r '.wallpaperDirectory' "${XDG_CONFIG_HOME:-$HOME/.config}/swim/config.json")
CACHE_DIR="$(nailgun thumbnails-for-theme "$WALLPAPER_DIR")"
# launch rofi menu
RofiSel=$( find "$CACHE_DIR" -type l -printf "%P\n" | sort | while read rfile
do
    echo -en "$rfile\x00icon\x1f${CACHE_DIR}/${rfile}/thumb\n"
done | rofi -dmenu -theme-str "${r_override}" -config "${RofiConf}" -select "$(basename "$(readlink "$SWIM_STATE_DIR/active/wallpaper")")" )


# apply wallpaper
if [ ! -z "${RofiSel}" ] ; then
    swimctl select "${RofiSel}"
    dunstify "t1" -a " ${RofiSel}" -i "${CACHE_DIR}/${RofiSel}/thumb" -r 91190 -t 2200
fi

#!/usr/bin/env sh

# set variables
CONF="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
RofiConf="$CONF/rofi/themeselect.rasi"


# scale for monitor x res
x_monres=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
monitor_scale=$(hyprctl -j monitors | jq '.[] | select (.focused == true) | .scale' | sed 's/\.//')
x_monres=$(( x_monres * 17 / monitor_scale ))


# set rofi override
hypr_border=`hyprctl -j getoption decoration:rounding | jq '.int'`
elem_border=$(( hypr_border * 5 ))
icon_border=$(( elem_border - 5 ))
r_override="element{border-radius:${elem_border}px;} element-icon{border-radius:${icon_border}px;size:${x_monres}px;}"


# launch rofi menu
ThemeSel=$( jq -r '.[]' "$CONF/chroma/themes.json" | while read THEME
do
    if [ -e "$STATE/swim/$THEME/wallpaper" ] ; then
        WP=$(readlink "$STATE/swim/$THEME/wallpaper")
    else
        WP=$(find "$CONF/chroma/themes/$THEME/swim/wallpapers/" -type f | head -n 1)
    fi

    CACHE_DIR="$(nailgun thumbnail-for-wp "$WP")"

    echo -en "$THEME\x00icon\x1f$CACHE_DIR/thumb\n"
done | rofi -dmenu -theme-str "${r_override}" -config $RofiConf)


# apply theme
if [ ! -z $ThemeSel ] ; then
    chromactl activate-theme "$ThemeSel"
    dunstify "t1" -a " ${ThemeSel}" -i "$CONF/dunst/icons/hyprdots.png" -r 91190 -t 2200
fi


#!/bin/bash

SWIM_CONFIG_DIR="${SWIM_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/swim}"
SWIM_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/swim"

# Another option would be a symlink!
WALLPAPER_DIR=$(jq -r '.wallpaperDirectory' "${SWIM_CONFIG_DIR}/config.json")

updateWallpaper() {
    if ! [ -f "${WALLPAPER_DIR}/$1" ]; then
        echo "Wallpaper $1 does not exist"
        exit 1
    fi

    ln -sf "${WALLPAPER_DIR}/$1" "${SWIM_STATE_DIR}/active/wallpaper"

    activateWallpaper
}

# spellcheck disable=SC2046
activateWallpaper() {
    local TRANS="${TRANSITION:-grow}"
    mapfile -t swwwArgs < <(jq -r '.extraSwwwArgs | .[]' "${SWIM_CONFIG_DIR}/config.json" | while read -r line; do
        eval "echo $line"
    done)
    swww \
        img "${SWIM_STATE_DIR}/active/wallpaper" \
        --transition-bezier ".43,1.19,1,.4" \
        --transition-type "$TRANS" \
        --transition-duration 0.7 \
        --transition-fps 120 \
        --invert-y \
        "${swwwArgs[@]}"

    WALLPAPER="${SWIM_STATE_DIR}/active/wallpaper" "$SWIM_CONFIG_DIR/activate"
}

case $1 in
    next)
        CURRENT_WALLPAPER="$(basename "$(readlink -f "${SWIM_STATE_DIR}/active/wallpaper")")"
        NEXT="$(find "$WALLPAPER_DIR/" -type f -printf '%P\n' | jq -nrR --arg current "$CURRENT_WALLPAPER" '[inputs] | .[(index($current) + 1) % length]')"
        TRANSITION="grow" updateWallpaper "$NEXT"
        ;;
    previous)
        CURRENT_WALLPAPER="$(basename "$(readlink -f "${SWIM_STATE_DIR}/active/wallpaper")")"
        NEXT="$(find "$WALLPAPER_DIR/" -type f -printf '%P\n'| jq -nrR --arg current "$CURRENT_WALLPAPER" '[inputs] | .[(index($current) + 0 - 1) % length]')"
        TRANSITION="outer" updateWallpaper "$NEXT"
        ;;
    select)
        updateWallpaper "$2"
        ;;
    list)
        find "$WALLPAPER_DIR/" -type f -printf '%P\n'
        ;;
    activate)
        activateWallpaper
        ;;
    *)
        echo "Usage: swimctl <command>"
        echo "Commands:"
        echo "  next"
        echo "  previous"
        echo "  select <wallpaper>"
        echo "  list"
        echo "  activate"
        exit 1
        ;;
esac

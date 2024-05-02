#!/usr/bin/env bash

NAILGUN_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nailgun"
NAILGUN_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/nailgun/store"
mkdir -p "$NAILGUN_STATE_DIR" "$NAILGUN_CACHE_DIR"

# TODO: also build cache on file hash, maybe?
cacheDir() {
    WP_HASH="$(echo -n "$(realpath "$1")" | sha256sum | cut -d' ' -f1)"
    WP_CACHE_DIR="$NAILGUN_CACHE_DIR/$WP_HASH"
    if [ "$1" -nt "$WP_CACHE_DIR" ]; then
        rm -rf "$WP_CACHE_DIR"
    fi
    mkdir -p "$WP_CACHE_DIR"
    echo -n "$WP_CACHE_DIR"
}

convertWallpaper() {
    WP_CACHE_DIR="$(cacheDir "$1")"

    if [ ! -f "$WP_CACHE_DIR/png" ]; then
        convert "$1" "PNG:$WP_CACHE_DIR/png"
    fi

    # The following convert commands are originally from prasanthrangan's hyprdots, available under the terms of GPLv3
    makeThumbnail "$1" "$WP_CACHE_DIR"

    if [ ! -f "$WP_CACHE_DIR/rofi" ] ; then
        convert "$1" -strip -resize 2000 -gravity center -extent 2000 -quality 90 "PNG:$WP_CACHE_DIR/rofi"
    fi

    if [ ! -f "$WP_CACHE_DIR/blur" ] ; then
        convert "$1" -strip -scale 10% -blur 0x3 -resize 100% "PNG:$WP_CACHE_DIR/blur"
    fi
    echo -n "$WP_CACHE_DIR"
}

makeThumbnail() {
    if [ ! -f "$2/thumb" ] ; then
        convert "$1" -strip -thumbnail 500x500^ -gravity center -extent 500x500 "PNG:$2/thumb"
    fi
}

makeThumbnailForTheme() {
    WP_HASH="$(cacheDir "$2")"
    makeThumbnail "$2" "$WP_HASH"
    ln -s "$WP_HASH" "$1/$(basename "$2")"
}

makeThumbCache() {
    CACHE_DIR="$(cacheDir "$1")"
    if [ "$(find "$1" -maxdepth 1 -type f -printf '.')" == "$(find "$CACHE_DIR" -maxdepth 1 -type d -printf '.')" ]; then
        echo -n "$CACHE_DIR"
        return
    fi

    rm -f "$CACHE_DIR"/*

    export NAILGUN_CACHE_DIR
    export -f cacheDir
    export -f makeThumbnail
    export -f makeThumbnailForTheme

    SHELL=bash parallel --will-cite makeThumbnailForTheme "$CACHE_DIR" ::: "$1"/*
    echo -n "$CACHE_DIR"
}

case "$1" in
    activate-wallpaper)
        CACHE_DIR="$(convertWallpaper "$2")"
        # Use hardlinks instead of symlinks so that the cache can be deleted
        # without breaking the setup.
        rm -rf "$NAILGUN_STATE_DIR/active-wallpaper"
        cp -al "$CACHE_DIR" "$NAILGUN_STATE_DIR/active-wallpaper"
    ;;
    thumbnails-for-theme)
        makeThumbCache "$2/"
    ;;
    thumbnail-for-wp)
        CACHE_DIR="$(cacheDir "$2")"
        makeThumbnail "$2" "$CACHE_DIR"
        echo -n "$CACHE_DIR"
    ;;
    *) exit 1 ;;
esac

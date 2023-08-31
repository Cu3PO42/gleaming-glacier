#!/bin/sh

next() {
  osascript -e 'tell application "Music" to play next track'
}

back() {
  osascript -e 'tell application "Music" to play previous track'
}

play() {
  osascript -e 'tell application "Music" to playpause'
}

repeat() {
  REPEAT=$(osascript -e 'tell application "Music" to get song repeat')
  case "$REPEAT" in
  "off")
    sketchybar -m --set applemusic.repeat icon.highlight=on icon=􀊟
    osascript -e 'tell application "Music" to set song repeat to one'
    ;;
  "one")
    sketchybar -m --set applemusic.repeat icon.highlight=on icon=􀊞
    osascript -e 'tell application "Music" to set song repeat to all'
    ;;
  *)
    sketchybar -m --set applemusic.repeat icon.highlight=off icon=􀊞
    osascript -e 'tell application "Music" to set song repeat to off'
    ;;
  esac
}

shuffle() {
  SHUFFLE=$(osascript -e 'tell application "Music" to get shuffle enabled')
  if [ "$SHUFFLE" = "false" ]; then
    sketchybar -m --set applemusic.shuffle icon.highlight=on
    osascript -e 'tell application "Music" to set shuffle enabled to true'
  else
    sketchybar -m --set applemusic.shuffle icon.highlight=off
    osascript -e 'tell application "Music" to set shuffle enabled to false'
  fi
}

update() {
  ISOPEN=$(osascript ~/.config/sketchybar/plugins/applemusic-isopen.applescript)
  args=()
  if [ "$ISOPEN" = "open" ]; then
    STATE=$(osascript -e 'tell application "Music" to get player state')
    if [ "$STATE" = "playing" ]; then
      TRACK=$(osascript -e 'tell application "Music" to get name of current track')
      ARTIST=$(osascript -e 'tell application "Music" to get artist of current track')
      ALBUM=$(osascript -e 'tell application "Music" to get album of current track')
      SHUFFLE=$(osascript -e 'tell application "Music" to get shuffling')
      REPEAT=$(osascript -e 'tell application "Music" to get repeating')
      rm /tmp/cover.*
      osascript ~/.config/sketchybar/plugins/applemusic-cover.applescript
      if [ -f /tmp/cover.png ]; then
        art="/tmp/cover.png"
      else
        art="/tmp/cover.jpg"
      fi
      if [ "$ARTIST" == "" ]; then
        args+=(--set applemusic.title label="$TRACK" drawing=on
          --set applemusic.album label="Podcast" drawing=on
          --set applemusic.artist label="$ALBUM" drawing=on)
      else
        args+=(--set applemusic.title label="$TRACK" drawing=on
          --set applemusic.album label="$ALBUM" drawing=on
          --set applemusic.artist label="$ARTIST" drawing=on)
      fi
      args+=(--set applemusic.play icon=􀊆
        --set applemusic.shuffle icon.highlight=$SHUFFLE
        --set applemusic.repeat icon.highlight=$REPEAT
        --set applemusic.cover background.image="$art"
        background.color=0x00000000
        --set applemusic.anchor drawing=on
        --set applemusic drawing=on)
    else
      args+=(--set applemusic.play icon=􀊄)
    fi
    sketchybar -m "${args[@]}"
  else
    args+=(--set applemusic.title drawing=off
      --set applemusic.artist drawing=off
      --set applemusic.anchor drawing=off popup.drawing=off
      --set applemusic.play icon=􀊄)
    sketchybar -m "${args[@]}"
  fi
}

mouse_clicked() {
  case "$NAME" in
  "applemusic.next")
    next
    ;;
  "applemusic.back")
    back
    ;;
  "applemusic.play")
    play
    ;;
  "applemusic.shuffle")
    shuffle
    ;;
  "applemusic.repeat")
    repeat
    ;;
  *)
    exit
    ;;
  esac
}

popup() {
  sketchybar --set applemusic.anchor popup.drawing=$1
}

case "$SENDER" in
"mouse.clicked")
  mouse_clicked
  ;;
"mouse.entered")
  popup on
  ;;
"mouse.exited" | "mouse.exited.global")
  popup off
  ;;
*)
  update
  ;;
esac

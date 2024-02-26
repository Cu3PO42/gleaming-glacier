#!/usr/bin/env bash

# These are the AppleScript keycodes for the number row.
# Don't ask me why they are the way they are.
translate_num() {
  case "$1" in
    "1") echo "18" ;;
    "2") echo "19" ;;
    "3") echo "20" ;;
    "4") echo "21" ;;
    "5") echo "23" ;;
    "6") echo "22" ;;
    "7") echo "26" ;;
    "8") echo "28" ;;
    "9") echo "25" ;;
    "10") echo "29" ;; # This is actually the zero button
    *) exit 3 ;;
  esac
}

switch () {
  if [ "$1" -le 10 ]; then
    osascript -e "tell application \"System Events\" to key code $(translate_num "$1") using {control down}"
  else
    osascript -e "tell application \"System Events\" to key code $(translate_num $(($1 - 10))) using {control down, option down}"
  fi
}

next() {
  # 124 is the right arrow key
  osascript -e 'tell application "System Events" to key code 124 using {control down}'
}

previous() {
  # 123 is the left arrow key
  osascript -e 'tell application "System Events" to key code 123 using {control down}'
}

case "$1" in
  "switch")
    switch "$2"
    ;;
  "next")
    next
    ;;
  "previous")
    previous
    ;;
  *)
    echo "Usage: switch <space> | next | previous"
    ;;
esac
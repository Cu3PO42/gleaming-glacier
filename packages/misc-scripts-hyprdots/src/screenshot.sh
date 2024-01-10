#!/usr/bin/env sh

swpy_dir="${XDG_CONFIG_DIR:-$HOME/.config}/swappy"
save_dir="${2:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
save_file="$save_dir/$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png')"
temp_screenshot="/tmp/screenshot.png"

mkdir -p $save_dir

function print_error
{
cat << "EOF"
    ./screenshot.sh <action>
    ...valid actions are...
        p : print all screens
        s : snip current screen
        sf : snip current screen (frozen)
        m : print focused monitor
EOF
}

case $1 in
p)  # print all outputs
    grimblast copysave screen - && swappy -f - -o "$save_file" ;;
s)  # drag to manually snip an area / click on a window to print it
    grimblast copysave area $temp_screenshot && swappy -f $temp_screenshot ;;
sf)  # frozen screen, drag to manually snip an area / click on a window to print it
    grimblast --freeze copysave area - && swappy -f - -o "$save_file" ;;
m)  # print focused monitor
    grimblast copysave output - && swappy -f - -o "$save_file" ;;
*)  # invalid option
    print_error ;;
esac

if [ -f "$save_dir/$save_file" ] ; then
    dunstify "t1" -a "saved in $save_dir" -i "$save_dir/$save_file" -r 91190 -t 2200
fi


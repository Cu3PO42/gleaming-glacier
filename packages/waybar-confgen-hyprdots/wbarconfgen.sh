#!/usr/bin/env sh

# This file consists of both the original wbarconfgen.sh and wbarstylegen.sh

# read control file and initialize variables

CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
waybar_dir="$CONF_DIR/waybar"
modules_dir="$waybar_dir/modules"
waybar_state="$STATE_DIR/hyprdots/waybar"

conf_file="$waybar_dir/config.jsonc"
conf_ctl="$waybar_dir/config.ctl"
in_file="$waybar_dir/modules/style.css"
out_file="$waybar_dir/style.mine.css"

mkdir -p "$waybar_state"
if [ ! -f "$waybar_state/active-idx" ]; then
    echo -n "0" > "$waybar_state/active-idx"
fi
ACTIVE_IDX=$(cat "$waybar_state/active-idx")

# update control file to set next/prev mode
if [ -n "${1+x}" ]; then
    num_files=$(wc -l < $conf_ctl)
    case $1 in
        n)
            ACTIVE_IDX=$(( (ACTIVE_IDX + 1) % num_files ))
            echo -n "$ACTIVE_IDX" > "$waybar_state/active-idx"
        ;;
        p)
            num_files=$(wc -l < $conf_ctl)
            ACTIVE_IDX=$(( (ACTIVE_IDX + num_files - 1) % num_files ))
        ;;
        *)
            echo "Unrecognized argument" >&2
            exit 1
        ;;
    esac
    echo -n "$ACTIVE_IDX" > "$waybar_state/active-idx"
fi

ACTIVE_CTL="$(sed "$(( ACTIVE_IDX + 1 ))q;d" $conf_ctl)"

# overwrite config from header module

export set_sysname=`hostnamectl hostname`
export w_position=`echo "$ACTIVE_CTL" | cut -d '|' -f 3`

export w_height=`echo "$ACTIVE_CTL" | cut -d '|' -f 2`
if [ -z $w_height ] ; then
    y_monres=`cat /sys/class/drm/*/modes | head -1 | cut -d 'x' -f 2`
    export w_height=$(( y_monres*2/100 ))
fi

export i_size=$(( w_height*6/10 ))
if [ $i_size -lt 12 ] ; then
    export i_size="12"
fi

export i_theme=`dconf read /org/gnome/desktop/interface/icon-theme | sed "s/'//g"`
export i_task=$(( w_height*6/10 ))
if [ $i_task -lt 16 ] ; then
    export i_task="16"
fi

envsubst < $modules_dir/header.jsonc > $conf_file


# module generator function
write_mod=""

gen_mod()
{
    local pos=$1
    local col=$2
    local mod=""

    mod=`echo "$ACTIVE_CTL" | cut -d '|' -f ${col}`
    mod="${mod//(/"custom/l_end"}"
    mod="${mod//)/"custom/r_end"}"
    mod="${mod//[/"custom/sl_end"}"
    mod="${mod//]/"custom/sr_end"}"
    mod="${mod//\{/"custom/rl_end"}"
    mod="${mod//\}/"custom/rr_end"}"
    mod="${mod// /"\",\""}"

    echo -e "\t\"modules-${pos}\": [\"custom/padd\",\"${mod}\",\"custom/padd\"]," >> $conf_file
    write_mod=`echo $write_mod $mod`
}


# write positions for modules

echo -e "\n\n// positions generated based on config.ctl //\n" >> $conf_file
gen_mod left 4
gen_mod center 5
gen_mod right 6


# copy modules/*.jsonc to the config

echo -e "\n\n// sourced from modules based on config.ctl //\n" >> $conf_file
echo "$write_mod" | sed 's/","/\n/g ; s/ /\n/g' | awk -F '/' '{print $NF}' | awk -F '#' '{print $1}' | awk '!x[$0]++' | while read mod_cpy
do

#    case ${w_position}-$(grep -E '"modules-left":|"modules-center":|"modules-right":' $conf_file | grep "$mod_cpy" | tail -1 | cut -d '"' -f 2 | cut -d '-' -f 2) in
#        top-left) export mod_pos=1;;
#        top-right) export mod_pos=2;;
#        bottom-right) export mod_pos=3;;
#        bottom-left) export mod_pos=4;;
#    esac

    if [ -f $modules_dir/$mod_cpy.jsonc ] ; then
        envsubst < $modules_dir/$mod_cpy.jsonc >> $conf_file
    fi
done

cat $modules_dir/footer.jsonc >> $conf_file


# calculate height from control file or monitor res

b_height="$w_height"

if [ -z $b_height ] || [ "$b_height" == "0" ]; then
    y_monres=`cat /sys/class/drm/*/modes | head -1 | cut -d 'x' -f 2`
    b_height=$(( y_monres*3/100 ))
fi


# calculate values based on height

export b_radius=$(( b_height*70/100 ))   # block rad 70% of height (type1)
export c_radius=$(( b_height*25/100 ))   # block rad 25% of height {type2}
export t_radius=$(( b_height*25/100 ))   # tooltip rad 25% of height
export e_margin=$(( b_height*30/100 ))   # block margin 30% of height
export e_paddin=$(( b_height*10/100 ))   # block padding 10% of height
export g_margin=$(( b_height*14/100 ))   # module margin 14% of height
export g_paddin=$(( b_height*15/100 ))   # module padding 15% of height
export w_radius=$(( b_height*30/100 ))   # workspace rad 30% of height
export w_margin=$(( b_height*10/100 ))   # workspace margin 10% of height
export w_paddin=$(( b_height*10/100 ))   # workspace padding 10% of height
export w_padact=$(( b_height*40/100 ))   # workspace active padding 40% of height
export s_fontpx=$(( b_height*38/100 ))   # font size 38% of height

if [ $b_height -lt 30 ] ; then
    export e_paddin=0
fi
if [ $s_fontpx -lt 10 ] ; then
    export s_fontpx=10
fi


# list modules and generate theme style

export modules_ls=$(grep -m 1 '".*.": {'  --exclude="$modules_dir/footer.jsonc" $modules_dir/*.jsonc | cut -d '"' -f 2 | awk -F '/' '{ if($1=="custom") print "#custom-"$NF"," ; else print "#"$NF","}')
envsubst < $in_file > $out_file


# override rounded couners

hypr_border=`hyprctl -j getoption decoration:rounding | jq '.int'`
if [ "$hypr_border" == "0" ] ; then
    sed -i "/border-radius: /c\    border-radius: 0px;" $out_file
fi

if systemctl --user is-active waybar; then
    # While a reload action is configured for waybar. It does not seem to work correctly.
    # This is likely an issue on waybar's end.
    systemctl --user restart waybar
fi
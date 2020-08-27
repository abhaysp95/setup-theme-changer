#!/usr/bin/env bash

# TODO:
# add support to compile dmenu
# add verbose and non-verbose mode
# add support for select in case user don't have fzf

# check if colorscheme name file exist(update it)
# this will automatically remove and put the new one in place(/tmp/vim-colorschemes)
# . ~/.cache/temp/sh_files/vcolors.sh --gen # this will executes the script as this script process

# change colorscheme for terminal
#. ~/.cache/temp/sh_files/vcolors.sh -c # this will executes the script as this script process
#echo "${SELECTED_THEME_NAME}"
alacritty_theme_path="/home/$(logname)/.config/alacritty/alacritty_themes"
alacritty_config="/home/$(logname)/.config/alacritty"
termite_theme_path="/home/$(logname)/.config/termite/termite_themes"
termite_config="/home/$(logname)/.config/termite"
xresources_theme_path="/home/$(logname)/.config/xresources_colors/"
dunst_config="/home/$(logname)/.config/dunst/dunstrc"
rofi_config="/home/$(logname)/.config/rofi/config.rasi"
bspwm_config="/home/$(logname)/.config/bspwm/bspwmrc"
dmenu_config="/home/$(logname)/Downloads/git-materials/dmenu_mybuild/config.h"
zathura_config="/home/$(logname)/.config/zathura/zathurarc"


selected_theme=""
function change_colorscheme_terminal() {
	# change colorscheme for n/vim
	. vcolors.sh -c # this will executes the script as this script process
	selected_theme="${SELECTED_THEME_NAME}"
	# echo "${selected_theme}"

	# change colorscheme for TERMINAL
	theme_files_count=0
	if [ "$TERMINAL" = "alacritty" ]; then
		theme_files=($(basename -a $(find "${alacritty_theme_path}" -type f -iname "*${selected_theme}*") 2>/dev/null))
		theme_files_count="${#theme_files[@]}"
		if [ ${theme_files_count} -gt 1 ]; then
			echo "Found more than with this colorscheme"
			selected_file=$(echo "${theme_files[@]}" | sed -e 's/ /\n/g' | fzf --prompt "Select file:" --border sharp --height 25%)
		else
			selected_file="${theme_files}"
		fi
		if [ -n "${selected_file}" ]; then
			if [ -f "${alacritty_theme_path}/${selected_file}" ]; then
				echo "Changing colorscheme for alacritty to ${selected_file}"
				cat "${alacritty_config}/base.yml" "${alacritty_theme_path}/${selected_file}" > "${alacritty_config}/alacritty.yml"
				echo "Changed successfully"
			else
				echo "Selected file not found, or not selected an option"
			fi
		else
			echo "Selection not found in the folder ${alacritty_theme_path}"
		fi

		# configuration for termite is still left
	elif [ "$TERMINAL" = "termite" ]; then
		theme_files=($(basename -a $(find "${termite_theme_path}" -type f -iname "*${selected_theme}*") 2>/dev/null))
		theme_files_count="${#theme_files[@]}"
		if [ ${theme_files_count} -gt 1 ]; then
			echo "Found more than with this colorscheme"
			selected_file=$(echo "${theme_files[@]}" | sed -e 's/ /\n/g' | fzf --prompt "Select file:" --border sharp --height 25%)
		else
			selected_file="${theme_files}"
		fi
		if [ -n "${selected_file}" ]; then
			if [ -f "${termite_theme_path}/${selected_file}" ]; then
				echo "Changing colorscheme ${selected_file}"
				cat "${termite_config}/base.yml" "${termite_theme_path}/${selected_file}" > "${termite_config}/test_termite.yml"
				echo "Changed successfully"
			else
				echo "Selected file not found, or not selected an option"
			fi
		else
			echo "Selection not found in the folder ${termite_theme_path}"
		fi
	else
		echo "$TERMINAL not found"
	fi
}

function change_colorscheme_xresources() {
	# this will change the colors for Xresources and all other tools which are dependent on it
	# like sxiv and my polybar build
	theme_files=($(basename -a $(find "${xresources_theme_path}" -type f -iname "*${selected_theme}*") 2>/dev/null))
	theme_files_count="${#theme_files[@]}"
	if [ ${theme_files_count} -gt 1 ]; then
		echo "Found more than with this colorscheme"
		selected_file=$(echo "${theme_files[@]}" | sed -e 's/ /\n/g' | fzf --prompt "Select file:" --border sharp --height 25%)
	else
		selected_file="${theme_files}"
	fi
	if [ -n "${selected_file}" ]; then
		if [ -f "${xresources_theme_path}/${selected_file}" ]; then
			echo "Selected file is: ${selected_file}"
			echo "Changing colorscheme"
			cat "${xresources_theme_path}"/"${selected_file}" "${xresources_theme_path}/base.Xresources" > /home/$(logname)/.Xresources
			xrdb ~/.Xresources  # get and set content
			echo "Changed successfully"
		else
			echo "Selected file not found, or not selected an option"
		fi
	else
		echo "Selection not found in the folder ${termite_theme_path}"
	fi
}

function change_colorscheme_dunst() {
	# get the colors first
	grey_xresources=$(sed -n -e 's/^\s*\*.\?color7\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)

	# change in dunstrc color file, # changing only for normal_urgency(which is most used)
	# awk -v color="$background_xresources" -i inplace -e '/background/{c++;if(c==2){sub("background.*[#a-fA-F0-9]+", "background = \"color");c=0}}1' dunstrc
	# don't understand what's wrong with above one(awk's), it's just not expanding the awk variable color for substitution

	# range based sed, from urgency_normal till newline is encountered (format /rangestart/,/rangestop/s/search/replace/)
	sed -i -E "/urgency_normal/,/^\s*$/s/(^\s*background\s*=\s*)\".+\"/\1\"${background_xresources}\"/" "${dunst_config}"
	sed -i -E "/urgency_normal/,/^\s*$/s/(^\s*foreground\s*=\s*)\".+\"/\1\"${foreground_xresources}\"/" "${dunst_config}"
	# from line 0 to first frame_color, and then replace, // means
	sed -i -e "0,/\(^\s*frame_color\s*=\s*\)\".\+\"/s//\1\"${grey_xresources}\"/" "${dunst_config}"

	# restart dunst
	[ -n "$(pidof dunst)" ] && kill "$(pidof dunst)" && dunst 2>/dev/null &
	sleep 0.5;
	notify-send -t 3000 "Dunst Reloaded"

	# print dunst changed color output
	printf "\n%s\n\n" "Colors for dunst on urgency_normal are: "
	printf "%s\n" "$(sed -n -E "/urgency_normal/,/^\s*$/s/(^\s*background\s*=\s*\".+\")/\1/p" "${dunst_config}")"
	printf "%s\n" "$(sed -n -E "/urgency_normal/,/^\s*$/s/(^\s*foreground\s*=\s*\".+\")/\1/p" "${dunst_config}")"
	printf "%s\n\n" "$(sed -n -e "0,/\(^\s*frame_color\s*=\s*\".\+\"\)/s//\1/p" "${dunst_config}")"
}

function change_colorscheme_rofi() {
	# get the colors for rofi from xresources
	selbg_xresources=$(sed -n -e 's/^\s*\*.\?color8\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	actbg_xresources=$(sed -n -e 's/^\s*\*.\?color2\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	urgbg_xresources=$(sed -n -e 's/^\s*\*.\?color1\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	# sed -n -e "s/\(^\s*background-color\s*:\s*\)[#[:alnum:]]\+;/\1#282828/p" config.rasi
	sed -i -e "s/\(^\s*background-color\s*:\s*\)[#[:alnum:]]\+;/\1${background_xresources};/" "${rofi_config}"
	sed -i -e "s/\(^\s*text-color\s*:\s*\)[#[:alnum:]]\+;/\1${foreground_xresources};/" "${rofi_config}"
	sed -i -e "s/\(^\s*selbg\s*:\s*\)[#[:alnum:]]\+;/\1${selbg_xresources};/" "${rofi_config}"
	sed -i -e "s/\(^\s*actbg\s*:\s*\)[#[:alnum:]]\+;/\1${actbg_xresources};/" "${rofi_config}"
	sed -i -e "s/\(^\s*urgbg\s*:\s*\)[#[:alnum:]]\+;/\1${urgbg_xresources};/" "${rofi_config}"
	sed -i -e "s/\(^\s*winbg\s*:\s*\)[#[:alnum:]]\+;/\1${background_xresources};/" "${rofi_config}"

	# print rofi changed color ouptut
	printf "\n%s\n\n" "Colors for rofi are: "
	printf "%s\n" "$(sed -n -e "/^\s*background-color\s*:\s*[#[:alnum:]]\+;/p" "${rofi_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*text-color\s*:\s*[#[:alnum:]]\+;/p" "${rofi_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*selbg\s*:\s*[#[:alnum:]]\+;/p" "${rofi_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*actbg\s*:\s*[#[:alnum:]]\+;/p" "${rofi_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*urgbg\s*:\s*[#[:alnum:]]\+;/p" "${rofi_config}")"
	printf "%s\n\n" "$(sed -n -e "/^\s*winbg\s*:\s*[#[:alnum:]]\+;/p" "${rofi_config}")"
}

function change_colorscheme_bspwm() {
	# sed -n -e 's/\(^.*normal_border_color\s*\)"[#[:alnum:]]\+"$/\1#282828/p' bspwmrc
	sed -i -e "s/\(^.*normal_border_color\s*\)\"[#[:alnum:]]\+\"$/\1\"${background_xresources}\"/" "${bspwm_config}"
	sed -i -e "s/\(^.*active_border_color\s*\)\"[#[:alnum:]]\+\"$/\1\"${background_xresources}\"/" "${bspwm_config}"
	sed -i -e "s/\(^.*focused_border_color\s*\)\"[#[:alnum:]]\+\"$/\1\"${foreground_xresources}\"/" "${bspwm_config}"

	printf "\n%s\n\n" "Colors changed for bspwm borders are: "
	sed -n -e "/^.*normal_border_color\s*\"[#[:alnum:]]\+\"$/p" "${bspwm_config}"
	sed -n -e "/^.*active_border_color\s*\"[#[:alnum:]]\+\"$/p" "${bspwm_config}"
	sed -n -e "/^.*focused_border_color\s*\"[#[:alnum:]]\+\"$/p" "${bspwm_config}"

	bspc wm -r  # reload the wm(reloads the polybar)
	sleep 1  # give time to properly load wm
}

function change_colorscheme_dmenu() {
	schemesel2=$(sed -n -e 's/^\s*\*.\?color8\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	schemeselhighlight2=$(sed -n -e 's/^\s*\*.\?color4\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	schemenormhighlight1=$(sed -n -e 's/^\s*\*.\?color14\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	schemeout2=$(sed -n -e 's/^\s*\*.\?color12\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	schememid2=$(sed -n -e 's/^\s*\*.\?color2\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)

	sed -i -e "s/\(^\s*\[SchemeNorm\].*{\s*\)\"[#[:alnum:]]\+\"\(.*$\)/\1\"${foreground_xresources}\"\2/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeNorm\].*{.*\)\"[#[:alnum:]]\+\"/\1\"${background_xresources}\"/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeSel\].*{\s*\)\"[#[:alnum:]]\+\"\(.*$\)/\1\"${foreground_xresources}\"\2/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeSel\].*{.*\)\"[#[:alnum:]]\+\"/\1\"${schemesel2}\"/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeSelHighlight\].*{.*\)\"[#[:alnum:]]\+\"/\1\"${schemeselhighlight2}\"/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeNormHighlight\].*{\s*\)\"[#[:alnum:]]\+\"\(.*$\)/\1\"${schemenormhighlight1}\"\2/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeOut\].*{\s*\)\"[#[:alnum:]]\+\"\(.*$\)/\1\"${background_xresources}\"\2/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeOut\].*{.*\)\"[#[:alnum:]]\+\"/\1\"${schemeout2}\"/" "${dmenu_config}"
	sed -i -e "s/\(^\s*\[SchemeMid\].*{.*\)\"[#[:alnum:]]\+\"/\1\"${schememid2}\"/" "${dmenu_config}"

	printf "\nColors after changing:\n\n"
	printf "%s\n" "$(sed -n -e "/^\s*\[SchemeNorm\].*/p" "${dmenu_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*\[SchemeSel\].*/p" "${dmenu_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*\[SchemeSelHighlight\].*/p" "${dmenu_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*\[SchemeNormHighlight\].*/p" "${dmenu_config}")"
	printf "%s\n" "$(sed -n -e "/^\s*\[SchemeOut\].*/p" "${dmenu_config}")"
	printf "%s\n\n" "$(sed -n -e "/^\s*\[SchemeMid\].*/p" "${dmenu_config}")"

	#cd "/home/$(logname)/Downloads/git-materials/dmenu_mybuild"
	#make install
	#cd -
}

function change_colorscheme_zathura() {
	background_xresources=$(sed -n -e 's/^\s*\*.\?background\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	foreground_xresources=$(sed -n -e 's/^\s*\*.\?foreground\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color8=$(sed -n -e 's/^\s*\*.\?color8\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color14=$(sed -n -e 's/^\s*\*.\?color14\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color1=$(sed -n -e 's/^\s*\*.\?color1\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color0=$(sed -n -e 's/^\s*\*.\?color0\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color5=$(sed -n -e 's/^\s*\*.\?color5\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color8=$(sed -n -e 's/^\s*\*.\?color8\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color11=$(sed -n -e 's/^\s*\*.\?color11\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	color4=$(sed -n -e 's/^\s*\*.\?color4\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)

	sed -i -e "s/\(.*default-bg\s*\)\".*\"/\1\"${background_xresources}\"/" "${zathura_config}"
	sed -i -e "s/\(.*default-fg\s*\)\".*\"/\1\"${foreground_xresources}\"/" "${zathura_config}"
	sed -i -e "s/\(.*statusbar-bg\s*\)\".*\"/\1\"${color8}\"/" "${zathura_config}"
	sed -i -e "s/\(.*statusbar-fg\s*\)\".*\"/\1\"${color14}\"/" "${zathura_config}"
	sed -i -e "s/\(.*inputbar-bg\s*\)\".*\"/\1\"${background_xresources}\"/" "${zathura_config}"
	sed -i -e "s/\(.*inputbar-fg\s*\)\".*\"/\1\"${foreground_xresources}\"/" "${zathura_config}"
	sed -i -e "s/\(.*notification-warning-bg\s*\)\".*\"/\1\"${color1}\"/" "${zathura_config}"
	sed -i -e "s/\(.*notification-warning-bg\s*\)\".*\"/\1\"${color0}\"/" "${zathura_config}"
	sed -i -e "s/\(.*highlight-color\s*\)\".*\"/\1\"${color6}\"/" "${zathura_config}"
	sed -i -e "s/\(.*highlight-active-color\s*\)\".*\"/\1\"${color12}\"/" "${zathura_config}"
	sed -i -e "s/\(.*completion-highlight-bg\s*\)\".*\"/\1\"${color5}\"/" "${zathura_config}"
	sed -i -e "s/\(.*completion-highlight-fg\s*\)\".*\"/\1\"${color0}\"/" "${zathura_config}"
	sed -i -e "s/\(.*completion-bg\s*\)\".*\"/\1\"${color8}\"/" "${zathura_config}"
	sed -i -e "s/\(.*completion-fg\s*\)\".*\"/\1\"${color11}\"/" "${zathura_config}"
	sed -i -e "s/\(.*notification-bg\s*\)\".*\"/\1\"${color4}\"/" "${zathura_config}"
	sed -i -e "s/\(.*notification-fg\s*\)\".*\"/\1\"${color0}\"/" "${zathura_config}"
	sed -i -e "s/\(.*recolor-darkcolor\s*\)\".*\"/\1\"${foreground_xresources}\"/" "${zathura_config}"
	sed -i -e "s/\(.*recolor-lightcolor\s*\)\".*\"/\1\"${background_xresources}\"/" "${zathura_config}"

	printf "\nColors after change:\n\n"
	sed -n -e "/.*default-bg/p" "${zathura_config}"
	sed -n -e "/.*default-fg/p" "${zathura_config}"
	sed -n -e "/.*statusbar-bg/p" "${zathura_config}"
	sed -n -e "/.*statusbar-fg/p" "${zathura_config}"
	sed -n -e "/.*inputbar-bg/p" "${zathura_config}"
	sed -n -e "/.*inputbar-fg/p" "${zathura_config}"
	sed -n -e "/.*notification-warning-bg/p" "${zathura_config}"
	sed -n -e "/.*notification-warning-bg/p" "${zathura_config}"
	sed -n -e "/.*highlight-color/p" "${zathura_config}"
	sed -n -e "/.*highlight-active-color/p" "${zathura_config}"
	sed -n -e "/.*completion-highlight-bg/p" "${zathura_config}"
	sed -n -e "/.*completion-highlight-fg/p" "${zathura_config}"
	sed -n -e "/.*completion-bg/p" "${zathura_config}"
	sed -n -e "/.*completion-fg/p" "${zathura_config}"
	sed -n -e "/.*notification-bg/p" "${zathura_config}"
	sed -n -e "/.*notification-fg/p" "${zathura_config}"
	sed -n -e "/.*recolor-darkcolor/p" "${zathura_config}"
	sed -n -e "/.*recolor-lightcolor/p" "${zathura_config}"
}

function change_colorschemes() {
	change_colorscheme_terminal
	change_colorscheme_xresources

	# since these two color codes are used too much, makes sense to use globally
	background_xresources=$(sed -n -e 's/^\s*\*.\?background\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)
	foreground_xresources=$(sed -n -e 's/^\s*\*.\?foreground\s*:\s*\([#a-fA-F0-9]\+$\)/\1/p' ~/.Xresources)

	change_colorscheme_bspwm
	change_colorscheme_dmenu
	change_colorscheme_dunst
	change_colorscheme_rofi

	#if [[ "${USER}" = root ]]; then
		#change_colorscheme_dmenu
	#fi
}

function gen_theme_file() {
	. ~/.cache/temp/sh_files/vcolors.sh --gen
}

function change_vim_background() {
	. ~/.cache/temp/sh_files/vcolors.sh --background $1
}

function get_help() {
	cat << EOH

Usage: settheme.sh [arguments]
	-h, --help		shows this help
	-bg, --background	changes the background between light and dark for n/vim
	-c, --colorscheme	shows fzf menu containing installed colorschemes to Choose
				colorscheme from it.
				This sets colorscheme for \$TERMINAL and .Xresources as well which
				in turn also changes theme for polybar and other tools too
	--gen	generate file with installed themes of n/vim to use with other scripts
Note: if no argument is provided then it'll be default to changing colorscheme.

Currently supported for n/vim, alacritty, termite, Xresources, polybar(with xresources), dunst and rofi

You have to compile dmenu yourself for now after runnning this script, work in progress

EOH
}

case $1 in
	-h|--help) get_help ;;
	-c|--colorscheme|'') change_colorschemes ;;
	--gen) gen_theme_file ;;
	-bg|--background) change_vim_background $2 ;;
	# --check) echo "No function to check currently" ;;
	--check) change_colorscheme_zathura ;;
	*) printf "Error! Invalid argument\tTry --help" ;;
esac

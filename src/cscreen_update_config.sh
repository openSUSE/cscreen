#!/bin/bash


# Author: Thomas Renninger <trenn@suse.de>
#
# This script compares an old cscreenrc file with a possibly
# modified new one. It then tries to connect to a running cscreen
# session and add, remove or restart windows accordingly so that
# the running cscreen session reflects the new cscreenrc again.

# $1: Old screenrc file (for example /etc/cscreenrc.old)
# $2: New screenrc file (for example /etc/cscreenrc)
# $3: The cscreen session to connect to (e.g. root/console or root/ppc)

SCREENRC='/etc/cscreenrc'

if [ -f "/etc/sysconfig/cscreen" ] ; then
    . /etc/sysconfig/cscreen
fi

DEBUG=0
function err_out()
{
    echo "$1"
    echo
    echo "cscreen_update_config.sh old_screenrc new_screenrc screen_session"
    exit 1
}

[[ $# != 3 ]] && err_out "Wrong parameter count $#, must be 3"

old_file="$1"
new_file="$2"
session="$3"

[ ! -r "$old_file" ] && err_out "Cannot read file: $old_file"
[ ! -r "$new_file" ] && err_out "Cannot read file: $new_file"

function add_window()
{
    local TITLE COMMAND
    local _host _status
    local debug='/run/cscreen/.debug'
    TITLE="$1"
    COMMAND="$2"

    test -w "${debug%/*}" || debug='/dev/null'

    # change defhstatus
    _host=$(echo $COMMAND | cut -d" " -f 3)
    _status="$(sed -n "/${_host}/{n;p}" $SCREENRC)"
    _status="$(echo $_status |sed 's/defhstatus "\(.*\)"/\1/')"
    echo $_host >> "${debug}"
    echo $_status >> "${debug}"
    if [ -n "$_status" ];then 
        echo "screen -x $session -X $_status" >> "${debug}"
        screen -x $session -X defhstatus "$_status" &>> "${debug}"
    fi
    echo "Add Window $TITLE: screen -x $session -X $COMMAND" >> "${debug}"
    screen -x $session -X $COMMAND
}

function remove_window()
{
    local TITLE COMMAND
    TITLE="$1"
    COMMAND="$2"
    echo "Remove Window $TITLE"
set -x
    screen -x "$session" -X -p "$TITLE" kill
set +x
}

function detect_modifications()
{
    local TYPE HOST COMMAND C_TYPE C_HOST C_COMMAND ENTRY CHECK
    logger XXXX
    IFS_OLD="$IFS"
    IFS=$'\n'
    # This one is tricky but works
    # You get lines like below:
    # Add/Remove([<>]|Command line|host_name
    # For example:
    # <|screen -t acrux                -L -I lanplus -H acrux-sp.arch.suse.de -U root -P hammer sol activate|acrux|
    # Which means that acrux entry got removed, the full command is
    # "screen -t acrux ..."
    diff_list=`diff $old_file $new_file |grep "screen -t"|sed -n -e 's/ \(screen -t \(\S*\).*\)/|\1|\2|/p'`
    [[ $DEBUG == 1 ]] && echo $diff_list
    for ENTRY in $diff_list;do
	IFS='|'
	set $ENTRY
	TYPE="$1"
	COMMAND="$2"
	HOST="$3"
	[[ $DEBUG == 1 ]] && echo "Add/Remove: $TYPE"
	[[ $DEBUG == 1 ]] && echo "Command line: $COMMAND"
	[[ $DEBUG == 1 ]] && echo "Host: $HOST"
	[[ $DEBUG == 1 ]] && echo
	# If we have an add, we have to double check whether we also
	# have a remove line for this host -> then we need to restart
	# the window with the new command.
	# And vice versa if we have remove, we have to double check
	# whether this host still shows up in an add line
	IFS=$'\n'
	for CHECK in $diff_list;do
	    set $CHECK
	    C_TYPE="$1"
	    C_COMMAND="$2"
	    C_HOST="$3"
	    [[ $DEBUG == 1 ]] && echo "Add/Remove: $C_TYPE"
	    [[ $DEBUG == 1 ]] && echo "Command line: $C_COMMAND"
	    [[ $DEBUG == 1 ]] && echo "Host: $C_HOST"
	    [[ $DEBUG == 1 ]] && echo
	    if [ "$HOST" = "$C_HOST" ] && [ "$TYPE" != "C_TYPE" ];then
		TYPE="R" # Restart
		break
	    fi
	done
	# DANGER: Below functions need default IFS!
	IFS="$IFS_OLD"
	case "$TYPE" in
	    ">")
		add_window "$HOST" "$COMMAND"
		;;
	    "<")
		remove_window "$HOST"
		;;
	    "R")
		remove_window "$HOST"
		add_window "$HOST" "$COMMAND"
		;;
	    *)
		echo "Bad type: $TYPE while parsing diff"
		;;
	esac
    done
}

detect_modifications
screen -x $session -Q sort

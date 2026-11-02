#!/bin/bash
# run $0 <bmc> [additional ssh parameters]
# cscreen_credentials.conf needs to provide cscreen_BMC_user= and cscreen_BMC_password
# For some reason ssh ignores additional -p N parameters, make sure the last -p N will be used.
# Use --ssh-port to specifiy the port number.
# Use --ssh-arg for single options, use --ssh-arg2 for options with a single argument.
# Commands to be run on the BMC must be quoted, in case any of the words starts with a dash.
# Luckily running commands on the BMC is not required, a plain login is expected to provide console access.
unset ${!LC_*} ${!LANG*} ${!SSH*} ${!DISPLAY*}
test -f /etc/cscreen-credentials.conf && . "$_"
ssh_arg_port=
args_ssh=()
args_remote=()
bmc_host="$1"
shift
declare -i delay=1
while test $# -gt 0
do
	: $1
	case "$1" in
	--ssh-port) ssh_arg_port=$2; shift;;
	--ssh-arg2) args_ssh+=("$2" "$3"); shift 2;;
	--ssh-arg) args_ssh+=("$2"); shift;;
	*) args_remote+=("$1");;
	esac
	shift
done
test -n "${ssh_arg_port}" || ssh_arg_port='2200'
args_ssh+=('-p' "${ssh_arg_port}")

if ping -c 1 -w 3 "${bmc_host}" &> /dev/null
then
	: good
else
	echo "Waiting for ${bmc_host} to respond to ping ..."
	until ping -i "${delay}" -w "${delay}" "${bmc_host}" &> /dev/null
	do
		sleep "$(( delay++ ))"
	done
	echo
fi

set -e
exec \
/usr/bin/env \
	SSHPASS="${cscreen_BMC_password}" \
	/usr/bin/sshpass -e \
	/usr/bin/ssh \
	-o 'CheckHostIP=no' \
	-o 'Compression=no' \
	-o 'ConnectTimeout=5' \
	-o 'ConnectionAttempts=5' \
	-o 'ForwardAgent=no' \
	-o 'GlobalKnownHostsFile=/dev/null' \
	-o 'IdentityFile=/dev/null' \
	-o 'ServerAliveCountMax=5' \
	-o 'ServerAliveInterval=5' \
	-o 'StrictHostKeyChecking=no' \
	-o 'UpdateHostKeys=no' \
	-o 'UserKnownHostsFile=/dev/null' \
	-l "${cscreen_BMC_user}" \
	"${args_ssh[@]}" \
	"${bmc_host}" \
	"${args_remote[@]}"

#!/bin/bash
# run $0 <bmc> [additional ssh parameters]
# cscreen_credentials.conf needs to provide cscreen_BMC_user= and cscreen_BMC_password
unset ${!LC_*} ${!LANG*} ${!SSH*} ${!DISPLAY*}
test -f /etc/cscreen-credentials.conf && . "$_"
bmc_host="$1"
shift
declare -i delay=1

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
	-p 2200 \
	-l "${cscreen_BMC_user}" \
	"${bmc_host}" \
	"$@"

#!/bin/bash
# run $0 <bmc> [extra ipmitool options]
# cscreen_credentials.conf needs to provide cscreen_BMC_user= and cscreen_BMC_password
unset ${!LC_*} ${!LANG*} ${!SSH*} ${!DISPLAY*}
test -f /etc/cscreen-credentials.conf && . "$_"
bmc_host="$1"
shift
declare -i delay=1
declare -a ipmitool_args
ipmitool_args+=( '-I' 'lanplus' )
ipmitool_args+=( '-U' "${cscreen_BMC_user}" )
ipmitool_args+=( '-P' "${cscreen_BMC_password}" )
ipmitool_args+=( '-H' "${bmc_host}" )
ipmitool_args+=( "$@" )
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
# Old BMC software fails to recognize a disconnected session.
# Maybe another session is still active, try to terminate it.
ipmitool "${ipmitool_args[@]}" sol deactivate
sleep 1
exec ipmitool "${ipmitool_args[@]}" sol activate

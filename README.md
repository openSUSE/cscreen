# cscreen
Allows to run multiple consoles in one screen session. Perfect for monitoring and logging all serial consoles in your data center in one screen instance

# Configuration

The file /etc/cscreenrc needs to be adjusted which commands for every required console window.

The command "screen", followed by its well documented command line options, creates new windows.
Typically the option "-t title" and "-L" to enable logging are used, followed by the actual command.

The optional command "defhstatus" can be used for additional information, which is then shown in the window status line.

````
defhstatus "ThisHost ttyS0"
screen -t OtherHost /dev/ttyS0 115200
defhstatus "RemoteHOST SOL-Wrapper"
screen -t RemoteHost -L /usr/share/cscreen/sol-via-ipmi.sh remotehost
defhstatus "RemoteHOST IPMI"
screen -t RemoteHost -L ipmitool -I lanplus -H remotehost -U username -P password sol activate
defhstatus "KVM VM"
screen -t VM -L virsh -c 'qemu:///system' console vm
````

## sol-via-ipmi.sh

This script waits until the remote host responds to ping.
Once it is reachable, an existing Serial-over-LAN connection will be terminated.
Then a new SOL connection will be established.
Note: the username and password of the BMC needs to be provided via the configuration file /etc/cscreen-credentials.conf

````
cscreen_BMC_user=X
cscreen_BMC_password=Y
````

## sol-via-ssh.sh

This script waits until the remote host responds to ping.
Once it is reachable, a new SOL connection via SSH to port 2200 will be established.
Note: the username and password of the BMC needs to be provided via the configuration file /etc/cscreen-credentials.conf
Note: this script requires sshpass to provide the SSH password to the remote host.

````
cscreen_BMC_user=X
cscreen_BMC_password=Y
````

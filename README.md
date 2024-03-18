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
defhstatus "RemoteHOST IPMI"
screen -t RemoteHost -L ipmitool -I lanplus -H remotehost -U username -P password sol activate
defhstatus "KVM VM"
screen -t VM -L virsh -c 'qemu:///system' console vm
````

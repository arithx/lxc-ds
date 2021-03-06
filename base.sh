if [ ! -e "/usr/bin/lxc-create" ]; then
    apt-get update
    apt-get install -qqy lxc
fi

if [ -z "$(cat /etc/lxc/default.conf | grep lxc.aa_profile)" ]; then
    echo "lxc.aa_profile = unconfined" >> /etc/lxc/default.conf
fi

if [ -z "$(cat /etc/lxc/default.conf | grep \#loop-control)" ]; then
    echo "lxc.cgroup.devices.allow = c 10:237 rwm #loop-control" >> /etc/lxc/default.conf
fi

if [ -z "$(cat /etc/lxc/default.conf | grep loop*)" ]; then
    echo "lxc.cgroup.devices.allow = b 7:* rwm # loop*" >> /etc/lxc/default.conf
fi

lxc-create -t ubuntu -n ds
mknod /var/lib/lxc/ds/rootfs/dev/loop-control c 10 237
lxc-start -n ds -d
lxc-wait -n ds -s RUNNING

# For whatever reason the LXC container can have network issues immediately after setting to running state
sleep 5

# Set cgroups manually
lxc-cgroup -n ds devices.allow "c 10:237 rwm"
lxc-cgroup -n ds devices.allow "b 7:* rwm"
sleep 5

lxc-attach -n ds -- bash -c "echo \"deb http://archive.ubuntu.com/ubuntu trusty-backports main restricted universe multiverse\" >> /etc/apt/sources.list"
lxc-attach -n ds -- bash -c "echo \"ubuntu\" | sudo -S apt-get update --fix-missing"
lxc-attach -n ds -- bash -c "echo \"ubuntu\" | sudo -S apt-get install -qqy wget"
lxc-attach -n ds -- bash -c "echo \"ubuntu\" | sudo -S wget -O - https://raw.github.com/arithx/shstack/master/base.sh | sh"
iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 80 -j DNAT --to-destination $(lxc-info -n ds -iH | egrep -v "192.")

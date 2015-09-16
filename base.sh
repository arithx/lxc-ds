if [ ! -e "/usr/bin/lxc-create" ]; then
    apt-get update
    apt-get install -qqy lxc
fi

echo "lxc.aa_profile = unconfined" >> /etc/lxc/default.conf
echo "lxc.cgroup.devices.allow = c 10:237 rwm #loop-control" >> /etc/lxc/default.conf
echo "lxc.cgroup.devices.allow = b 7:* rwm # loop*" >> /etc/lxc/default.conf
lxc-create -t ubuntu -n ds
lxc-start -n ds -d
lxc-attach -n ds -- echo "ubuntu" | sudo apt-get update -qqy wget
lxc-attach -n ds -- echo "ubuntu" | sudo wget -O - https://raw.github.com/arithx/shstack/master/base.sh | sh

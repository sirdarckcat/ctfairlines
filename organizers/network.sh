#!/bin/bash

set -x

ip netns add net_mcdu
ip netns add net_fdr

ip link add veth_mcdu netns net_mcdu type veth peer name veth_fdr netns net_fdr

ip netns exec net_mcdu ip addr add 172.20.4.8/24 dev veth_mcdu
ip netns exec net_fdr ip addr add 172.20.4.2/24 dev veth_fdr

ip netns exec net_mcdu ip link set veth_mcdu up
ip netns exec net_fdr ip link set veth_fdr up

ip netns exec net_fdr nsjail/nsjail -N --chroot /chroots/cdls -- /bin/bash -c '/root/main' &

sleep 1s
ip netns exec net_fdr /chroots/mcdu/cdls/unlock CTF{TheGoodFlag}
ip netns exec net_fdr nsjail/nsjail -N --chroot /chroots/blackbox -- /bin/bash -c 'cd /fdr/; ./fdr.sh' &


ip netns exec net_mcdu nsjail/nsjail --cap CAP_NET_BIND_SERVICE -g 0 -u 0 -N --chroot /chroots/mcdu -- /bin/bash -c '/out/shell :9923' &


sleep 1d

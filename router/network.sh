#!/bin/bash

ip netns add net_mcdu
ip netns add net_fdr

ip link add veth_mcdu netns net_mcdu type veth peer name veth_fdr netns net_fdr

ip netns exec net_mcdu ip addr add 172.20.4.8/24 dev veth_mcdu
ip netns exec net_fdr ip addr add 172.20.4.2/24 dev veth_fdr

ip netns exec net_mcdu ip link set veth_mcdu up
ip netns exec net_fdr ip link set veth_fdr up

ip netns exec net_mcdu ip link set lo up
ip netns exec net_fdr ip link set lo up

ip netns exec net_fdr nsjail/nsjail -t $TIME -N --chroot /chroots/cdls -- /root/main &

sleep 1s

&>>/tmp/setflag.log ip netns exec net_fdr /chroots/mcdu/cdls/unlock $FLAG

sleep 1s

ip netns exec net_fdr nsjail/nsjail -t $TIME -N --chroot /chroots/blackbox -T /fdr/log -- /bin/bash -c 'cd /fdr/; ALL_PROXY=socks5://127.0.0.1:1080 NO_PROXY=172.20.4.8,127.0.0.1 ./fdr.sh' &

&>>/tmp/mcdushell.log ip netns exec net_mcdu /sbin/runuser -u user -g user -- nsjail/nsjail -t $TIME -N --chroot /chroots/mcdu -T /tmp -- /out/shell :9923 &

sleep 3s

&>>/tmp/mcdu9923.log timeout -k 10s ${TIME}s ip netns exec net_mcdu socat unix-listen:/tmp/mcdu,fork,forever tcp-connect:127.0.0.1:9923 &
&>>/tmp/mcdu23.log timeout -k 10s ${TIME}s ip netns exec net_mcdu socat tcp-listen:23,fork,forever tcp-connect:127.0.0.1:9923 &

sleep 1s

timeout -k 10s ${TIME}s ip netns exec net_fdr socat -d -d unix-client:/tmp/dns,forever udp-recvfrom:53,fork,reuseaddr,bind=127.0.0.1 &

while :; do timeout -k 10s 30s ip netns exec net_fdr socat -d -d unix-client:/tmp/proxy tcp-listen:1080,reuseaddr,bind=127.0.0.1; done

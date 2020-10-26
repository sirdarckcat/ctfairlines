#!/bin/bash

set -x

iface="test"
net1=$iface-net1
net2=$iface-net2
veth1=$iface-veth1
veth2=$iface-veth2

ip netns add $net1
ip netns add $net2

ip link add $veth1 netns $net1 type veth peer name $veth2 netns $net2

# MCDU
ip netns exec $net1 ip addr add 172.20.0.8/24 dev $veth1

# FDR/CDLS/GW
ip netns exec $net2 ip addr add 172.20.0.2/24 dev $veth2

ip netns exec $net1 ip link set $veth1 up
ip netns exec $net2 ip link set $veth2 up

ip netns exec $net1 nsjail/nsjail -g 1000 -u 1000 -d -N --chroot / -- /bin/bash -c 'yes broadcastedpacket | socat - UDP-DATAGRAM:172.20.0.255:1234,broadcast'

ip netns exec $net2 nsjail/nsjail -g 1000 -u 1000 -N --chroot / -- /bin/bash -c 'socat - UDP-RECV:1234,reuseaddr | head -n 3'

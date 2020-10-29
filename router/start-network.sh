#!/bin/bash

python3 pow.py ask 1337 || exit

sleep 1
echo -e '\E[H\E[J'
sleep 1

echo -e '\e[31;47m'
awk '{print $0; system("sleep .1");}' banner.txt
echo -e '\e[m'

sleep 1
echo -e '\E[H\E[J'
sleep 1

echo -e '\033[0;36m[[ DHCP >> DNS >> Config ]]\033[0m'

dns=""
while [ -z "$dns" ]
do
  echo -en 'DNS Server Address (format: 8.8.8.8:53) \n> '
  read dns
done

echo "[*] Setting DNS Server to $dns"

tmp=$(mktemp -d)
timeout -k 10s 600s ./socks $tmp/proxy "$dns" 2>&1 >$tmp/socks.log &
timeout -k 10s 600s socat "udp:$dns" unix-listen:$tmp/dns,fork,reuseaddr 2>&1 >$tmp/dns.log &

sleep 1s

nsjail/nsjail -t 600 -u 0:0:65536 -g 0:0:65536 --proc_rw --keep_caps -D $PWD -T /run/netns -B $tmp:/tmp --rw --chroot / -l $tmp/network.log ./network.sh &

(sleep 600s; rm -rf $tmp) &

echo -n 'Loading (waiting for MCDU)'
while [ ! -S $tmp/mcdu ]; do echo -n . && sleep 1; done

echo '!'

while :
do
  echo -en 'Send cockpit door lock combination \n> '
  read input
  sleep 1
  echo "cdls unlock $input" | socat unix-client:$tmp/mcdu -
  sleep 1
done

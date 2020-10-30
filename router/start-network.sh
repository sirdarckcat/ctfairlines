#!/bin/bash

python3 pow.py ask $POW || exit

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
  dns=$(echo "$dns" | egrep '([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{1,5}')
done

echo "[*] Setting DNS Server to $dns"

tmp=$(mktemp -d)
&>>$tmp/proxy.log timeout -k 10s ${TIME}s ./socks $tmp/proxy "$dns" &
&>>$tmp/dns.log timeout -k 10s ${TIME}s socat -d -d "udp:$dns" unix-listen:$tmp/dns,fork,reuseaddr &

sleep 1s

&>>$tmp/networkout.log nsjail/nsjail -t $TIME -u 0:0:65536 -g 0:0:65536 --proc_rw --keep_caps -D $PWD -T /run/netns -B $tmp:/tmp --rw --chroot / -l $tmp/network.log -E FLAG -E TIME -- /bin/bash ./network.sh &

(sleep ${TIME}s; rm -rf $tmp) &

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

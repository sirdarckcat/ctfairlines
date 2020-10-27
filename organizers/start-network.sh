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
  echo -en 'DNS Server Address \n> '
  read dns
done

echo "[*] Setting DNS Server to $dns"

tmp=$(mktemp -d)
./socks $tmp/proxy "$dns" 2>&1 >$tmp/socks.log &

sleep 1s

nsjail/nsjail -d -u 0:0:65536 -g 0:0:65536 --proc_rw --keep_caps -D $PWD -T /run/netns -B $tmp:/tmp --rw --chroot / -l $tmp/network.log ./network.sh

echo -n 'Loading (waiting for MCDU)'
while [ ! -S $tmp/mcdu ]; do echo -n . && sleep 1; done

echo '!'

input=" "
while [ ! -z "$input" ]
do
  echo -en 'Send cockpit door lock combination \n> '
  read input || exit
  if [ -z "$input" ]; then rm -rf $tmp; exit; fi
  sleep 1
  echo "cdls unlock $input" | socat unix-client:$tmp/mcdu -
  sleep 1
done

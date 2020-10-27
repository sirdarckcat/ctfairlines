#!/bin/bash

sleep 1

echo -e '\e[31;47m'

cat banner.txt

echo -e '\e[m'

sleep 5s

echo -en 'DNS Server Address \n> '
read dns

echo '[*] Setting DNS Server to $dns'

tmp=$(mktemp -d)
./socks $tmp/proxy "$dns" 2>&1 >$tmp/socks.log &

sleep 1s

nsjail/nsjail -d -u 0:0:65536 -g 0:0:65536 --proc_rw --keep_caps -D $PWD -T /run/netns -B $tmp:/tmp --rw --chroot / ./network.sh

echo -n 'Loading (waiting for MCDU)'
while [ ! -S $tmp/mcdu ]; do echo -n . && sleep 1; done

echo '!'

while :
do
  echo -en 'Send door lock combination \n> '
  read input || (cat $tmp/*.log; rm -rf $tmp; exit)
  echo Sending $input to CDLS
  echo "cdls unlock $input" | socat unix-client:$tmp/mcdu -
done

#!/bin/bash

nsjail/nsjail --proc_rw --keep_caps -D $PWD -T /run/netns --rw --chroot / ./network.sh

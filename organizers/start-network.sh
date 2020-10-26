#!/bin/bash

nsjail/nsjail --proc_rw --keep_caps -T /run/netns -D $PWD --chroot / ./network.sh

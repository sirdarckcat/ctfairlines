#!/bin/bash

nsjail/nsjail --proc_rw --keep_caps -D $PWD -T /run/netns --chroot / ./network.sh

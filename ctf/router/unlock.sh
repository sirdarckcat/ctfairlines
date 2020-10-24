#!/bin/bash

echo "$@" | socat - tcp:172.20.4.8:23

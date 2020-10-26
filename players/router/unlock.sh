#!/bin/bash

echo cdls unlock "$@" | socat - tcp:172.20.4.8:23

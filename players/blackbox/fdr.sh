#!/bin/bash

shopt -s nullglob

python3 fdr.py&

cd log

while true; do
  for f in fdr-log*; do
    curl -sSL -F "fdr-log=@$f" http://fdr.example.com/fdr
  done;
  sleep 10s
done;

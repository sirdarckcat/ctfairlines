#!/bin/bash

python3 fdr.py&

while true; do
  shopt -s nullglob
  for f in fdr-log*; do
    curl -F "fdr-log=@$f" http://fdr.example.com/fdr && rm $f
  done;
  sleep 10s
done;

#!/bin/sh

while true; do
  fio "$@"
  sleep 1
done

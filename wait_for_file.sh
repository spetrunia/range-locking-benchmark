#!/bin/bash

FILE=$1

if [[ "x${FILE}y" == "xy" ]] ; then
  echo "Usage: $0 filename"
  exit 1
fi

while true ; do 
  if [[ -f $FILE ]] ; then
    echo "Wait for $FILE finished"
    exit 0
  fi
  sleep 3
done


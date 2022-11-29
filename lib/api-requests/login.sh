#!/usr/bin/env sh

ENDPOINT="https://api-dev.meetin.gs/v1/login"

if [ "$1" == "" ]; then
  echo "Usage: $0 <request-file.json>"
  exit 1
fi

curl -H'Content-Type:application/json' -X POST -d @${1}  $ENDPOINT

#!/usr/bin/env sh

curl -H "user_id:4633" -H "dic:x" https://api-dev.meetin.gs/v1/users/4633/meetings > list-meetings_response.json

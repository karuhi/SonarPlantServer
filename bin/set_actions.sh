#!/usr/bin/env bash

#curl http://localhost:8888/matches/1/action -X POST \
#  -H 'Authorization: AA' -H 'Content-Type: application/json' \
#  -d '[{"agentID": 100, "dx": -1, "dy": 0, "type": "remove"}]'

#curl http://localhost:8888/matches/1/action -X POST \
#  -H 'Authorization: AA' -H 'Content-Type: application/json' \
#  -d '{"actions": [{"agentID": 101, "dx": -1, "dy": -1, "type": "move"}]}'


curl http://169.254.252.164:8888/matches/1/action -X POST \
  -H 'Authorization: AA' -H 'Content-Type: application/json' \
  -d '[{"agentID": 100, "dx": 0, "dy": 1, "type": "move"}]'
#
#curl http://localhost:8888/matches/1/action -X POST \
#  -H 'Authorization: BB' -H 'Content-Type: application/json' \
#  -d '[{"agentID": 103, "dx": 0, "dy": -1, "type": "move"}]'

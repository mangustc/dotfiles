#!/usr/bin/env bash

cd "$(dirname "$0")"

cd ./degoog
docker compose stop
cd ..

./start-containers.sh

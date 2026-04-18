#!/usr/bin/env sh

cd "$(dirname "$0")"

cd ./degoog
docker compose stop
cd ..

./start-containers.sh

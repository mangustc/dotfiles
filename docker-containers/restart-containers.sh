#!/usr/bin/env sh

cd "$(dirname "$0")"

docker container stop degoog

./start-containers.sh

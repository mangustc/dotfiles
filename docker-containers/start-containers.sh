#!/usr/bin/env sh

cd "$(dirname "$0")"

cd ./degoog
docker compose up -d
cd ..

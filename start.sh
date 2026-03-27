#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

echo "Starting core services..."
docker compose up -d

if [ -f extras/.env ]; then
  echo "Starting extras..."
  docker compose --env-file .env --env-file extras/.env -f extras/docker-compose.yml up -d
else
  echo "Skipping extras (extras/.env not found — copy extras/.env.example to get started)"
fi

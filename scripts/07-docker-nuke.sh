#!/usr/bin/env bash
set -euo pipefail

echo "Stopping all containers..."
docker ps -q | xargs -r docker stop

echo "Removing all containers..."
docker ps -aq | xargs -r docker rm -f

echo "Removing all images..."
docker images -aq | xargs -r docker rmi -f

echo "Removing all volumes..."
docker volume ls -q | xargs -r docker volume rm -f

echo "Removing all networks (except default ones)..."
docker network ls -q | xargs -r docker network rm 2>/dev/null || true

echo "Pruning builder cache..."
docker builder prune -af || true

echo "System prune..."
docker system prune -af --volumes

echo "Done. Docker is cleaned."
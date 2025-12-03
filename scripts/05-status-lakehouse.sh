#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
ROOT_DIR="${BASE_DIR%/}/lakehouse_repo"

if [ ! -d "$ROOT_DIR" ]; then
  echo "Lakehouse repo not found at: ${ROOT_DIR}"
  echo "Set LAKEHOUSE_HOME or run 02-clone-lakehouse.sh first."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed or not in PATH"
  exit 1
fi

cd "$ROOT_DIR"

echo "Docker containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" \
  | grep -E "minio|nessie|trino|airflow|postgres|redis" || true

echo
echo "Lake compose:"
docker compose -f docker-compose-lake.yaml ps || true

echo
echo "Trino compose:"
docker compose -f docker-compose-trino.yaml ps || true

echo
echo "Airflow compose:"
docker compose -f docker-compose-airflow.yaml ps || true

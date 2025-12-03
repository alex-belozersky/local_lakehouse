#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
ROOT_DIR="${BASE_DIR%/}/lakehouse_repo"

if [ ! -d "$ROOT_DIR" ]; then
  echo "Lakehouse repo not found at: ${ROOT_DIR}"
  echo "Set LAKEHOUSE_HOME or run 02-clone-lakehouse.sh first."
  exit 1
fi

cd "$ROOT_DIR"

if [ ! -f ".env" ]; then
  echo ".env is missing. Run 03-generate-env.sh or 03-regenerate-env.sh first."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "docker is not installed or not in PATH"
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose plugin is not available"
  exit 1
fi

if [ ! -x "./manage-lakehouse.sh" ]; then
  chmod +x ./manage-lakehouse.sh || true
fi

echo "Building Airflow image from local Dockerfile..."
docker compose -f docker-compose-airflow.yaml build

echo "Starting lakehouse via manage-lakehouse.sh..."
./manage-lakehouse.sh start

. ./.env

MINIO_USER="${MINIO_ROOT_USER:-minioadmin}"
MINIO_PASS="${MINIO_ROOT_PASSWORD:-minioadmin}"

AIRFLOW_USER="${AIRFLOW_USERNAME:-airflow}"
AIRFLOW_PASS="${AIRFLOW_PASSWORD:-airflow}"

TRINO_USER="${TRINO_USERNAME:-trino}"
TRINO_PASS="${TRINO_PASSWORD:-trino}"

TRINO_PORT_VALUE="${TRINO_PORT:-8080}"
AIRFLOW_API_PORT_VALUE="${AIRFLOW_API_PORT:-8081}"

echo
echo "============================================================"
echo " LAKEHOUSE STARTED"
echo "============================================================"
echo
echo "MinIO:"
echo "  URL:      http://localhost:9001"
echo "  User:     ${MINIO_USER}"
echo "  Password: ${MINIO_PASS}"
echo
echo "Airflow:"
echo "  URL:      http://localhost:${AIRFLOW_API_PORT_VALUE}"
echo "  User:     ${AIRFLOW_USER}"
echo "  Password: ${AIRFLOW_PASS}"
echo
echo "Trino Coordinator:"
echo "  URL:      http://localhost:${TRINO_PORT_VALUE}"
echo "  User:     ${TRINO_USER}"
echo "  Password: ${TRINO_PASS}"
echo
echo "============================================================"
echo```
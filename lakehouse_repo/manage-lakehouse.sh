#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PASSWORD_SCRIPT="${SCRIPT_DIR}/trino_config/create-password-db.sh"
if [ -f "$PASSWORD_SCRIPT" ] && [ ! -x "$PASSWORD_SCRIPT" ]; then
    chmod +x "$PASSWORD_SCRIPT"
fi

load_env() {
  ENV_FILE="${SCRIPT_DIR}/.env"

  if [ -f "$ENV_FILE" ]; then
    . "$ENV_FILE"
  fi

  MINIO_ROOT_USER="${MINIO_ROOT_USER:-minioadmin}"
  MINIO_ROOT_PASSWORD="${MINIO_ROOT_PASSWORD:-minioadmin}"

  AIRFLOW_USERNAME="${AIRFLOW_USERNAME:-airflow}"
  AIRFLOW_PASSWORD="${AIRFLOW_PASSWORD:-airflow}"

  TRINO_USERNAME="${TRINO_USERNAME:-trino}"
  TRINO_PASSWORD="${TRINO_PASSWORD:-trino}"

  TRINO_PORT="${TRINO_PORT:-8080}"
  AIRFLOW_API_PORT="${AIRFLOW_API_PORT:-8081}"
}

start_services() {
  echo "Starting Local Lakehouse services..."

  cd "$SCRIPT_DIR"

  echo "Creating Trino password file..."
  ./trino_config/create-password-db.sh

  echo "Starting data lake services (MinIO + Nessie)..."
  docker compose -f docker-compose-lake.yaml up -d
  sleep 5

  echo "Starting Trino query engine..."
  docker compose -f docker-compose-trino.yaml up -d
  sleep 30

  echo "Starting Airflow orchestration services..."
  docker compose -f docker-compose-airflow.yaml up -d
  sleep 5

  load_env

  echo "All services started successfully."
}
init_trino() {
  echo "Initializing Trino schemas..."
  docker exec trino-coordinator trino --catalog iceberg --file /etc/trino/init.sql
  echo "Schemas (landing, staging, curated) created in Trino Iceberg Catalog."
  echo
}

load_dbt_seed_data() {
  echo "Loading CSV seed data via dbt..."
  
  export TRINO_USERNAME="${TRINO_USERNAME:-trino}"
  export TRINO_PASSWORD="${TRINO_PASSWORD:-trino}"
  
  dbt seed --project-dir ./dags/dbt_trino --profiles-dir ./dags/dbt_trino
  echo "CSV files loaded to landing schema via dbt."
  echo
}
stop_services() {
  echo "Stopping Local Lakehouse services..."

  cd "$SCRIPT_DIR"

  echo "Stopping Airflow services..."
  docker compose -f docker-compose-airflow.yaml down -v

  echo "Stopping Trino services..."
  docker compose -f docker-compose-trino.yaml down -v

  echo "Stopping data lake services..."
  docker compose -f docker-compose-lake.yaml down -v

  echo "All services stopped and volumes cleaned up."
  echo
}

case "${1:-help}" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  *)
    echo "Local Lakehouse Management Script"
    echo
    echo "Usage: $0 [start|stop]"
    echo
    echo "Commands:"
    echo "  start    Start all lakehouse services (MinIO, Nessie, Trino, Airflow)"
    echo "  stop     Stop all services and clean up volumes"
    echo
    echo "After starting, you can access:"
    echo "  - MinIO Console:  http://localhost:9001"
    echo "  - Trino Web UI:   http://localhost:\${TRINO_PORT:-8080}"
    echo "  - Airflow Web UI: http://localhost:\${AIRFLOW_API_PORT:-8081}"
    ;;
esac


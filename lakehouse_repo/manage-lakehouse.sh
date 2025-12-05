#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for script in create-password-db.sh generate-configs.sh; do
  if [ -f "$SCRIPT_DIR/trino_config/$script" ] && [ ! -x "$SCRIPT_DIR/trino_config/$script" ]; then
    chmod +x "$SCRIPT_DIR/trino_config/$script"
  fi
done

load_env() {
  if [ -f "$SCRIPT_DIR/.env" ]; then
    . "$SCRIPT_DIR/.env"
  fi
}

start_services() {
  echo "Starting lakehouse services..."

  cd "$SCRIPT_DIR"

  load_env

  if [ -x "./trino_config/generate-configs.sh" ]; then
    ./trino_config/generate-configs.sh
  fi

  if [ -x "./trino_config/create-password-db.sh" ]; then
    ./trino_config/create-password-db.sh
  fi

  docker compose -f docker-compose-lake.yaml up -d
  sleep 5

  docker compose -f docker-compose-trino.yaml up -d
  sleep 45

  load_env

  if docker compose -f docker-compose-trino.yaml ps -q trino-coordinator >/dev/null 2>&1; then
    docker exec -e TRINO_PASSWORD="$TRINO_PASSWORD" trino-coordinator trino \
      --server http://localhost:8080 \
      --user "$TRINO_USERNAME" \
      --password \
      --file /etc/trino/init.sql 2>/dev/null || true
  fi

  docker compose -f docker-compose-airflow.yaml up -d
  sleep 5

  echo "Services started"
}

load_dbt_seed_data() {
  load_env
  export TRINO_USERNAME="$TRINO_USERNAME"
  export TRINO_PASSWORD="$TRINO_PASSWORD"

  dbt seed --project-dir ./dags/dbt_trino --profiles-dir ./dags/dbt_trino
}

stop_services() {
  echo "Stopping lakehouse services..."

  cd "$SCRIPT_DIR"

  docker compose -f docker-compose-airflow.yaml down -v
  docker compose -f docker-compose-trino.yaml down -v
  docker compose -f docker-compose-lake.yaml down -v

  echo "Services stopped"
}

case "${1:-}" in
  start)
    start_services
    ;;
  stop)
    stop_services
    ;;
  seed)
    load_dbt_seed_data
    ;;
  *)
    echo "Usage: $0 {start|stop|seed}"
    exit 1
    ;;
esac

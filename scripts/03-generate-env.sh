#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
REPO="${BASE_DIR%/}/lakehouse_repo"
ENV_FILE="${REPO}/.env"

if [ ! -d "$REPO" ]; then
  echo "ERROR: Lakehouse repo not found at: $REPO"
  echo "Set LAKEHOUSE_HOME or run clone script first."
  exit 1
fi

cd "$REPO"

random_hex() {
  openssl rand -hex 32
}

generate_fernet() {
  python3 - << 'EOF'
from cryptography.fernet import Fernet
print(Fernet.generate_key().decode())
EOF
}

echo "Generating new .env at ${ENV_FILE}..."

cat > "$ENV_FILE" <<EOF
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=$(random_hex)

AIRFLOW__CORE__FERNET_KEY=$(generate_fernet)
AIRFLOW__WEBSERVER__SECRET_KEY=$(random_hex)

AIRFLOW_USERNAME=airflow
AIRFLOW_PASSWORD=$(random_hex)

TRINO_USERNAME=trino
TRINO_PASSWORD=$(random_hex)

NESSIE_USERNAME=nessie
NESSIE_PASSWORD=$(random_hex)

TRINO_PORT=8080
AIRFLOW_API_PORT=8081

AIRFLOW_UID=50000
EOF

echo ".env created at ${ENV_FILE}"
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
MINIO_ENDPOINT=http://minio:9000
MINIO_INIT_WRITE_TEST=false
MINIO_BUCKETS=local-lakehouse,rest-lakehouse,jdbc-lakehouse

AIRFLOW__CORE__FERNET_KEY=$(generate_fernet)
AIRFLOW__WEBSERVER__SECRET_KEY=$(random_hex)

AIRFLOW_USERNAME=airflow
AIRFLOW_PASSWORD=$(random_hex)

TRINO_USERNAME=trino
TRINO_PASSWORD=$(random_hex)

TRINO_INTERNAL_SECRET=$(random_hex)

NESSIE_USERNAME=nessie
NESSIE_PASSWORD=$(random_hex)

TRINO_PORT=8080
AIRFLOW_API_PORT=8081

AIRFLOW_UID=50000

POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(random_hex)
POSTGRES_DB=postgres

AIRFLOW_DB=airflow_db
AIRFLOW_DB_USER=airflow_user
AIRFLOW_DB_PASS=$(random_hex)

POLARIS_DB=polaris_db
POLARIS_DB_USER=polaris_user
POLARIS_DB_PASS=$(random_hex)

TRINO_DB=trino_db
TRINO_DB_USER=trino_user
TRINO_DB_PASS=$(random_hex)

# Polaris root principal
POLARIS_REALM=default-realm
POLARIS_CLIENT_ID=root
POLARIS_CLIENT_SECRET=polaris-root-secret-change-me
POLARIS_BOOTSTRAP_CREDENTIALS=default-realm,root,polaris-root-secret-change-me

# Polaris catalog
POLARIS_WAREHOUSE_NAME=default
POLARIS_ALLOWED_LOCATION=s3://rest-lakehouse/
POLARIS_DEFAULT_BASE_LOCATION=s3://rest-lakehouse/
POLARIS_SCOPE=PRINCIPAL_ROLE:ALL
POLARIS_S3_ROLE_ARN=arn:aws:iam::000000000000:role/polaris-minio-role

EOF

echo ".env created at ${ENV_FILE}"
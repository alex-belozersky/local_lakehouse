#!/usr/bin/env bash
set -euo pipefail

JUPYTERHUB_USER="${JUPYTERHUB_USER:-jovyan}"
JUPYTERHUB_NOTEBOOK_DIR="${JUPYTERHUB_NOTEBOOK_DIR:-/home/jovyan/work}"

POLARIS_CATALOG_NAME="${POLARIS_CATALOG_NAME:-polaris}"
POLARIS_CATALOG_URI="${POLARIS_CATALOG_URI:-http://polaris:8181/api/catalog}"
POLARIS_WAREHOUSE_NAME="${POLARIS_WAREHOUSE_NAME:-default}"
POLARIS_REALM="${POLARIS_REALM:-default-realm}"
POLARIS_CLIENT_ID="${POLARIS_CLIENT_ID:-}"
POLARIS_CLIENT_SECRET="${POLARIS_CLIENT_SECRET:-}"
POLARIS_SCOPE="${POLARIS_SCOPE:-PRINCIPAL_ROLE:ALL}"

AWS_REGION="${AWS_REGION:-us-east-1}"
AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-}"
AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-}"
S3_ENDPOINT="${S3_ENDPOINT:-http://minio:9000}"
S3_PATH_STYLE_ACCESS="${S3_PATH_STYLE_ACCESS:-true}"

mkdir -p /srv/jupyterhub/runtime
mkdir -p "${JUPYTERHUB_NOTEBOOK_DIR}"
mkdir -p "/home/${JUPYTERHUB_USER}/.config/pyiceberg"

chown -R "${JUPYTERHUB_USER}:users" /srv/jupyterhub
chown -R "${JUPYTERHUB_USER}:users" "/home/${JUPYTERHUB_USER}"

cat > "/home/${JUPYTERHUB_USER}/.config/pyiceberg/.pyiceberg.yaml" <<EOF
catalog:
  ${POLARIS_CATALOG_NAME}:
    type: rest
    uri: ${POLARIS_CATALOG_URI}
    warehouse: ${POLARIS_WAREHOUSE_NAME}
    credential: ${POLARIS_CLIENT_ID}:${POLARIS_CLIENT_SECRET}
    scope: ${POLARIS_SCOPE}
    header.Polaris-Realm: ${POLARIS_REALM}

    s3.endpoint: ${S3_ENDPOINT}
    s3.region: ${AWS_REGION}
    s3.access-key-id: ${AWS_ACCESS_KEY_ID}
    s3.secret-access-key: ${AWS_SECRET_ACCESS_KEY}
    s3.path-style-access: ${S3_PATH_STYLE_ACCESS}
EOF

chown "${JUPYTERHUB_USER}:users" "/home/${JUPYTERHUB_USER}/.config/pyiceberg/.pyiceberg.yaml"
chmod 600 "/home/${JUPYTERHUB_USER}/.config/pyiceberg/.pyiceberg.yaml"

echo "Generated PyIceberg config:"
echo "/home/${JUPYTERHUB_USER}/.config/pyiceberg/.pyiceberg.yaml"

exec jupyterhub -f /srv/jupyterhub/jupyterhub_config.py
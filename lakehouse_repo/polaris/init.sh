#!/usr/bin/env bash
set -euo pipefail

POLARIS_CATALOG_BASE="${POLARIS_CATALOG_BASE:-http://polaris:8181}"
POLARIS_MGMT_BASE="${POLARIS_MGMT_BASE:-http://polaris:8181}"

CLIENT_ID="${POLARIS_CLIENT_ID:?POLARIS_CLIENT_ID is required}"
CLIENT_SECRET="${POLARIS_CLIENT_SECRET:?POLARIS_CLIENT_SECRET is required}"
SCOPE="${POLARIS_SCOPE:-PRINCIPAL_ROLE:ALL}"

WAREHOUSE_NAME="${POLARIS_WAREHOUSE_NAME:-default}"
ALLOWED_LOCATION="${POLARIS_ALLOWED_LOCATION:-s3://local-lakehouse/}"
DEFAULT_BASE_LOCATION="${POLARIS_DEFAULT_BASE_LOCATION:-s3://local-lakehouse/}"

until curl -sS -o /dev/null "${POLARIS_CATALOG_BASE}/api/catalog/v1/config"; do
  echo "[polaris-init] Waiting for Polaris API..."
  sleep 2
done

echo "[polaris-init] Getting access token..."
TOKEN="$(
  curl -fsS -X POST "${POLARIS_CATALOG_BASE}/api/catalog/v1/oauth/tokens" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=${CLIENT_ID}" \
    --data-urlencode "client_secret=${CLIENT_SECRET}" \
    --data-urlencode "scope=${SCOPE}" \
  | jq -r '.access_token'
)"

if [[ -z "${TOKEN}" || "${TOKEN}" == "null" ]]; then
  echo "[polaris-init] ERROR: cannot obtain access token"
  exit 1
fi

echo "[polaris-init] Waiting for management API..."
until curl -fsS -H "Authorization: Bearer ${TOKEN}" "${POLARIS_MGMT_BASE}/api/management/v1/catalogs" >/dev/null 2>&1; do
  sleep 2
done

echo "[polaris-init] Ensuring warehouse/catalog exists: ${WAREHOUSE_NAME}"
if curl -fsS -H "Authorization: Bearer ${TOKEN}" "${POLARIS_MGMT_BASE}/api/management/v1/catalogs" \
  | jq -e --arg name "${WAREHOUSE_NAME}" '.catalogs[]? | select(.name==$name)' >/dev/null; then
  echo "[polaris-init] Already exists."
  exit 0
fi

curl -fsS -X POST "${POLARIS_MGMT_BASE}/api/management/v1/catalogs" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"${WAREHOUSE_NAME}\",
    \"type\": \"INTERNAL\",
    \"properties\": {
      \"default-base-location\": \"${DEFAULT_BASE_LOCATION}\"
    },
    \"storageConfigInfo\": {
      \"storageType\": \"S3\",
      \"allowedLocations\": [\"${ALLOWED_LOCATION}\"]
    }
  }"

echo "[polaris-init] Created."
#!/usr/bin/env bash
set -euo pipefail

POLARIS_CATALOG_BASE="${POLARIS_CATALOG_BASE:-http://polaris:8181}"
POLARIS_MGMT_BASE="${POLARIS_MGMT_BASE:-http://polaris:8181}"

REALM="${POLARIS_REALM:-}"

CLIENT_ID="${POLARIS_CLIENT_ID:?POLARIS_CLIENT_ID is required}"
CLIENT_SECRET="${POLARIS_CLIENT_SECRET:?POLARIS_CLIENT_SECRET is required}"
SCOPE="${POLARIS_SCOPE:-PRINCIPAL_ROLE:ALL}"

WAREHOUSE_NAME="${POLARIS_WAREHOUSE_NAME:?POLARIS_WAREHOUSE_NAME is required}"
ALLOWED_LOCATION="${POLARIS_ALLOWED_LOCATION:?POLARIS_ALLOWED_LOCATION is required}"
DEFAULT_BASE_LOCATION="${POLARIS_DEFAULT_BASE_LOCATION:?POLARIS_DEFAULT_BASE_LOCATION is required}"
S3_ROLE_ARN="${POLARIS_S3_ROLE_ARN:?POLARIS_S3_ROLE_ARN is required}"

REALM_HEADERS=()
if [[ -n "${REALM}" ]]; then
  REALM_HEADERS=(-H "Polaris-Realm: ${REALM}")
fi

echo "[polaris-init] POLARIS_CATALOG_BASE=${POLARIS_CATALOG_BASE}"
echo "[polaris-init] POLARIS_MGMT_BASE=${POLARIS_MGMT_BASE}"
echo "[polaris-init] POLARIS_REALM=${REALM}"
echo "[polaris-init] POLARIS_CLIENT_ID=${CLIENT_ID}"
echo "[polaris-init] POLARIS_WAREHOUSE_NAME=${WAREHOUSE_NAME}"
echo "[polaris-init] POLARIS_ALLOWED_LOCATION=${ALLOWED_LOCATION}"
echo "[polaris-init] POLARIS_DEFAULT_BASE_LOCATION=${DEFAULT_BASE_LOCATION}"
echo "[polaris-init] POLARIS_S3_ROLE_ARN=${S3_ROLE_ARN}"

echo "[polaris-init] Waiting for Polaris API..."

until curl -sS -o /dev/null "${POLARIS_CATALOG_BASE}/api/catalog/v1/config"; do
  echo "[polaris-init] Waiting for Polaris API..."
  sleep 2
done

echo "[polaris-init] Getting access token..."

TOKEN_RESPONSE="$(
  curl -fsS -X POST "${POLARIS_CATALOG_BASE}/api/catalog/v1/oauth/tokens" \
    "${REALM_HEADERS[@]}" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "grant_type=client_credentials" \
    --data-urlencode "client_id=${CLIENT_ID}" \
    --data-urlencode "client_secret=${CLIENT_SECRET}" \
    --data-urlencode "scope=${SCOPE}"
)"

TOKEN="$(printf '%s' "${TOKEN_RESPONSE}" | jq -r '.access_token // empty')"

if [[ -z "${TOKEN}" || "${TOKEN}" == "null" ]]; then
  echo "[polaris-init] ERROR: cannot obtain access token"
  echo "[polaris-init] Token response:"
  echo "${TOKEN_RESPONSE}"
  exit 1
fi

echo "[polaris-init] Access token received"

AUTH_HEADERS=(
  -H "Authorization: Bearer ${TOKEN}"
)

if [[ -n "${REALM}" ]]; then
  AUTH_HEADERS+=(-H "Polaris-Realm: ${REALM}")
fi

echo "[polaris-init] Waiting for management API..."

until curl -fsS \
  "${AUTH_HEADERS[@]}" \
  "${POLARIS_MGMT_BASE}/api/management/v1/catalogs" >/dev/null 2>&1; do
  echo "[polaris-init] Waiting for management API..."
  sleep 2
done

echo "[polaris-init] Management API is ready"

echo "[polaris-init] Getting existing catalogs..."

CATALOGS_STATUS="$(
  curl -sS -o /tmp/polaris-catalogs-response.json -w "%{http_code}" \
    "${AUTH_HEADERS[@]}" \
    "${POLARIS_MGMT_BASE}/api/management/v1/catalogs"
)"

if [[ "${CATALOGS_STATUS}" != "200" ]]; then
  echo "[polaris-init] ERROR: cannot list catalogs"
  echo "[polaris-init] HTTP status: ${CATALOGS_STATUS}"
  echo "[polaris-init] Response:"
  cat /tmp/polaris-catalogs-response.json || true
  exit 1
fi

echo "[polaris-init] Ensuring warehouse/catalog exists: ${WAREHOUSE_NAME}"

if jq -e --arg name "${WAREHOUSE_NAME}" '.catalogs[]? | select(.name == $name)' /tmp/polaris-catalogs-response.json >/dev/null; then
  echo "[polaris-init] Already exists."
  exit 0
fi

echo "[polaris-init] Catalog does not exist. Creating..."

echo "[polaris-init] POLARIS_S3_ROLE_ARN=${S3_ROLE_ARN}"

CREATE_PAYLOAD="$(
  jq -n \
    --arg name "${WAREHOUSE_NAME}" \
    --arg defaultBaseLocation "${DEFAULT_BASE_LOCATION}" \
    --arg allowedLocation "${ALLOWED_LOCATION}" \
    --arg roleArn "${S3_ROLE_ARN}" \
    '{
      catalog: {
        name: $name,
        type: "INTERNAL",
        properties: {
          "default-base-location": $defaultBaseLocation
        },
        storageConfigInfo: {
          storageType: "S3",
          allowedLocations: [
            $allowedLocation
          ],
          roleArn: $roleArn
        }
      }
    }'
)"

echo "[polaris-init] Create catalog payload:"
echo "${CREATE_PAYLOAD}"

CREATE_STATUS="$(
  curl -sS -o /tmp/polaris-create-catalog-response.json -w "%{http_code}" \
    -X POST "${POLARIS_MGMT_BASE}/api/management/v1/catalogs" \
    "${AUTH_HEADERS[@]}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    --data-binary "${CREATE_PAYLOAD}"
)"

if [[ "${CREATE_STATUS}" == "200" || "${CREATE_STATUS}" == "201" || "${CREATE_STATUS}" == "204" || "${CREATE_STATUS}" == "409" ]]; then
  echo "[polaris-init] Created or already exists."
  echo "[polaris-init] Response:"
  cat /tmp/polaris-create-catalog-response.json || true
  exit 0
fi

echo "[polaris-init] ERROR: failed to create catalog"
echo "[polaris-init] HTTP status: ${CREATE_STATUS}"
echo "[polaris-init] Response:"
cat /tmp/polaris-create-catalog-response.json || true
exit 1
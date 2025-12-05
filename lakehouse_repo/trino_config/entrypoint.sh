#!/usr/bin/env bash
set -euo pipefail

PASSWORD_FILE="/etc/trino/password.db"

if [[ -z "${TRINO_USERNAME:-}" || -z "${TRINO_PASSWORD:-}" ]]; then
  echo "ERROR: TRINO_USERNAME or TRINO_PASSWORD is not set"
  exit 1
fi

echo "${TRINO_USERNAME}:${TRINO_PASSWORD}" > "$PASSWORD_FILE"
chmod 600 "$PASSWORD_FILE"

exec /usr/lib/trino/bin/run-trino
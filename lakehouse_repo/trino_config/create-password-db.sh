#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$ROOT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    set -a
    source <(grep -v '^#' "$ENV_FILE" | sed '/^$$/d')
    set +a
fi

TRINO_USER="${TRINO_USERNAME:-trino}"
TRINO_PASS="${TRINO_PASSWORD:-trino}"
PASSWORD_DB="$SCRIPT_DIR/password.db"

echo "Generating bcrypt password hash for user: $TRINO_USER"
echo "Output file: $PASSWORD_DB"

htpasswd -B -C 10 -b -c "$PASSWORD_DB" "$TRINO_USER" "$TRINO_PASS"

chmod 600 "$PASSWORD_DB"
echo "password.db created successfully."
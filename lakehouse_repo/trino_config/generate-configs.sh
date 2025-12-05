#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

if [ ! -f "$ROOT_DIR/.env" ]; then
  echo "ERROR: .env not found in $ROOT_DIR. Run 03-generate-env.sh first."
  exit 1
fi

source "$ROOT_DIR/.env"

if [ -z "${TRINO_INTERNAL_SECRET:-}" ]; then
  echo "ERROR: TRINO_INTERNAL_SECRET is not set in .env. Regenerate env first."
  exit 1
fi

cat > "$SCRIPT_DIR/coordinator/config.properties" <<EOF
coordinator=true
node-scheduler.include-coordinator=false

http-server.http.port=8080
discovery.uri=http://trino-coordinator:8080

http-server.authentication.type=PASSWORD
http-server.authentication.allow-insecure-over-http=true

internal-communication.shared-secret=${TRINO_INTERNAL_SECRET}
internal-communication.https.required=false
EOF

cat > "$SCRIPT_DIR/worker/config.properties" <<EOF
coordinator=false

http-server.http.port=8080
discovery.uri=http://trino-coordinator:8080

http-server.authentication.allow-insecure-over-http=true

internal-communication.shared-secret=${TRINO_INTERNAL_SECRET}
internal-communication.https.required=false
EOF

echo "Trino configuration files generated with internal secret: ${TRINO_INTERNAL_SECRET}"

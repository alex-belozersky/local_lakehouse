#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
REPO="${BASE_DIR%/}/lakehouse_repo"
ENV_FILE="${REPO}/.env"
GENERATE_ENV_SCRIPT="${LAKEHOUSE_SCRIPTS_HOME:-/opt/scripts}/03-generate-env.sh"

if [ ! -d "$REPO" ]; then
  echo "ERROR: Lakehouse repo not found at: $REPO"
  echo "Set LAKEHOUSE_HOME or run clone script first."
  exit 1
fi

cd "$REPO"

echo "Stopping all lakehouse services..."
./manage-lakehouse.sh stop || true

if [ -f "$ENV_FILE" ]; then
  echo "Removing old .env..."
  rm -f "$ENV_FILE"
fi

echo "Generating new .env..."
"$GENERATE_ENV_SCRIPT"

echo
echo "New .env generated:"
echo "-----------------------------------------"
cat "$ENV_FILE"
echo "-----------------------------------------"

echo "Environment regeneration completed."
echo "Start the lakehouse stack with:"
echo "  ${LAKEHOUSE_SCRIPTS_HOME:-/opt/scripts}/04-start-lakehouse.sh"

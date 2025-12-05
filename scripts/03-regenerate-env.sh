#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
REPO="${BASE_DIR%/}/lakehouse_repo"
ENV_FILE="${REPO}/.env"

DEFAULT_SCRIPTS_HOME="${SCRIPT_DIR}"
GENERATE_ENV_SCRIPT="${LAKEHOUSE_SCRIPTS_HOME:-$DEFAULT_SCRIPTS_HOME}/03-generate-env.sh"

if [ ! -d "$REPO" ]; then
  echo "ERROR: Lakehouse repo not found at: $REPO"
  echo "Set LAKEHOUSE_HOME or run 01- or 02-clone-lakehouse.sh first."
  exit 1
fi

cd "$REPO"

if [ ! -f "./manage-lakehouse.sh" ]; then
  echo "ERROR: manage-lakehouse.sh not found in $REPO"
  exit 1
fi

if [ ! -x "./manage-lakehouse.sh" ]; then
  chmod +x ./manage-lakehouse.sh || true
fi

echo "Stopping all lakehouse services..."
./manage-lakehouse.sh stop || true

if [ -f "$ENV_FILE" ]; then
  echo "Removing old .env..."
  rm -f "$ENV_FILE"
fi

if [ ! -f "$GENERATE_ENV_SCRIPT" ]; then
  echo "ERROR: 03-generate-env.sh not found at: $GENERATE_ENV_SCRIPT"
  exit 1
fi

if [ ! -x "$GENERATE_ENV_SCRIPT" ]; then
  chmod +x "$GENERATE_ENV_SCRIPT" || true
fi

echo "Generating new .env using: $GENERATE_ENV_SCRIPT"
"$GENERATE_ENV_SCRIPT"

if [ ! -f "$ENV_FILE" ]; then
  echo "ERROR: .env was not created at: $ENV_FILE"
  exit 1
fi

echo
echo "New .env generated:"
echo "-----------------------------------------"
cat "$ENV_FILE"
echo "-----------------------------------------"

echo
echo "Environment regeneration completed."
echo "To start the lakehouse stack run:"
echo "  ${LAKEHOUSE_SCRIPTS_HOME:-$SCRIPT_DIR}/04-start-lakehouse.sh"

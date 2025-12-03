#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
ROOT_DIR="${BASE_DIR%/}/lakehouse_repo"

if [ ! -d "$ROOT_DIR" ]; then
  echo "Lakehouse repo not found at: ${ROOT_DIR}"
  echo "Set LAKEHOUSE_HOME or run 02-clone-lakehouse.sh first."
  exit 1
fi

cd "$ROOT_DIR"

if [ ! -x "./manage-lakehouse.sh" ]; then
  chmod +x ./manage-lakehouse.sh || true
fi

echo "Stopping Lakehouse stack..."
./manage-lakehouse.sh stop

echo "Lakehouse stopped."
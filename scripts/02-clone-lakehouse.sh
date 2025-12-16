#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/alex-belozersky/lakehouse-devkit.git"
BRANCH="main"
SPARSE_PATH="lakehouse_repo"

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
TARGET_DIR="${BASE_DIR%/}/lakehouse_repo"

echo "Using lakehouse base directory: ${BASE_DIR}"
echo "Lakehouse repo will be placed in: ${TARGET_DIR}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed"
  exit 1
fi

if [ -d "$TARGET_DIR" ]; then
  echo "Cleaning existing directory: ${TARGET_DIR}"
  rm -rf "$TARGET_DIR"
fi

mkdir -p "$(dirname "$TARGET_DIR")"

WORK_DIR="$(mktemp -d)"
echo "Cloning only '$SPARSE_PATH' directory into temp workdir: ${WORK_DIR}"

git clone --branch "$BRANCH" --depth 1 \
  --filter=blob:none \
  --sparse \
  "$REPO_URL" "$WORK_DIR"

cd "$WORK_DIR"
git sparse-checkout set "$SPARSE_PATH"

echo "Moving files from ${SPARSE_PATH}/ to ${TARGET_DIR}/"
cp -R "${WORK_DIR}/${SPARSE_PATH}/." "$TARGET_DIR/"

rm -rf "$WORK_DIR"

echo "Latest repo files ready at ${TARGET_DIR}"

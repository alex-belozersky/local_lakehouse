#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/itslavrov/lakehouse-devkit.git"
REPO_REF="3bdb9271fdaf2dc309ce93f827f109f83079a136"
SPARSE_PATH="lakehouse_repo"

BASE_DIR="${LAKEHOUSE_HOME:-/opt}"
TARGET_DIR="${BASE_DIR%/}/lakehouse_repo"

echo "Using lakehouse base directory: ${BASE_DIR}"
echo "Lakehouse repo will be placed in: ${TARGET_DIR}"

if ! command -v git >/dev/null 2>&1; then
  echo "git is not installed"
  exit 1
fi

mkdir -p "$TARGET_DIR"

WORK_DIR="$(mktemp -d)"
echo "Cloning into temp workdir: ${WORK_DIR}"

git clone --no-checkout "$REPO_URL" "$WORK_DIR"
git -C "$WORK_DIR" sparse-checkout init --cone
git -C "$WORK_DIR" sparse-checkout set "$SPARSE_PATH"
git -C "$WORK_DIR" checkout "$REPO_REF"

echo "Moving files from ${SPARSE_PATH}/ to ${TARGET_DIR}/"
cp -R "${WORK_DIR}/${SPARSE_PATH}/." "$TARGET_DIR/"

rm -rf "$WORK_DIR"

echo "Repo files ready at ${TARGET_DIR}"
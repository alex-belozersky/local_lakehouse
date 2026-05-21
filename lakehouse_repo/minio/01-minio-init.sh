#!/bin/sh

set -eu

log() {
  echo "[minio-init] $*"
}

fail() {
  echo "[minio-init] ERROR: $*" >&2
  exit 1
}

MINIO_ENDPOINT="${MINIO_ENDPOINT:-http://minio:9000}"
MINIO_INIT_WRITE_TEST="${MINIO_INIT_WRITE_TEST:-false}"

[ -n "${MINIO_ROOT_USER:-}" ] || fail "MINIO_ROOT_USER is empty"
[ -n "${MINIO_ROOT_PASSWORD:-}" ] || fail "MINIO_ROOT_PASSWORD is empty"
[ -n "${MINIO_BUCKETS:-}" ] || fail "MINIO_BUCKETS is empty"

log "Starting MinIO init"
log "MINIO_ENDPOINT=${MINIO_ENDPOINT}"
log "MINIO_BUCKETS=${MINIO_BUCKETS}"
log "MINIO_INIT_WRITE_TEST=${MINIO_INIT_WRITE_TEST}"

log "Waiting for MinIO..."

until mc alias set local "${MINIO_ENDPOINT}" "${MINIO_ROOT_USER}" "${MINIO_ROOT_PASSWORD}" >/dev/null 2>&1; do
  log "MinIO is not ready yet, waiting..."
  sleep 2
done

log "MinIO is ready"

# Поддерживаем оба формата:
# MINIO_BUCKETS=local-lakehouse,rest-lakehouse
# MINIO_BUCKETS="local-lakehouse rest-lakehouse"
NORMALIZED_BUCKETS="$(echo "${MINIO_BUCKETS}" | tr ',' ' ')"

for bucket in ${NORMALIZED_BUCKETS}; do
  [ -n "${bucket}" ] || continue

  case "${bucket}" in
    s3://*|http://*|https://*|/*)
      fail "Invalid bucket name '${bucket}'. Use bucket name only, for example: rest-lakehouse"
      ;;
  esac

  case "${bucket}" in
    *"/"* )
      fail "Invalid bucket name '${bucket}'. Bucket name must not contain slash"
      ;;
  esac

  log "Ensuring bucket exists: ${bucket}"
  mc mb --ignore-existing "local/${bucket}"

  if [ "${MINIO_INIT_WRITE_TEST}" = "true" ]; then
    log "Running write test for bucket: ${bucket}"

    test_file="/tmp/minio-init-healthcheck.txt"
    test_object="local/${bucket}/_healthcheck/minio-init-healthcheck.txt"

    echo "minio-init healthcheck" > "${test_file}"

    mc cp "${test_file}" "${test_object}" >/dev/null
    mc cat "${test_object}" >/dev/null
    mc rm "${test_object}" >/dev/null

    log "Write test passed for bucket: ${bucket}"
  fi
done

log "Existing buckets:"
mc ls local

log "Done"
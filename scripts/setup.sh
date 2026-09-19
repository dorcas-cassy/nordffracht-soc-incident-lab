#!/bin/sh
set -eu

LAB_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM="$LAB_ROOT/.runtime/wazuh-docker"

if [ ! -d "$UPSTREAM/.git" ]; then
  mkdir -p "$LAB_ROOT/.runtime"
  git clone --depth 1 --branch v4.14.7 \
    https://github.com/wazuh/wazuh-docker.git "$UPSTREAM"
fi

if [ "$(git -C "$UPSTREAM" describe --tags --exact-match 2>/dev/null)" != 'v4.14.7' ]; then
  echo 'The cached Wazuh checkout is not v4.14.7; remove .runtime/wazuh-docker and retry.' >&2
  exit 1
fi

# Docker Desktop may return EDEADLK for bind mounts from a protected Desktop
# folder. Stage the pinned upstream config in a local temp path that Docker
# can read. The Git checkout remains in the ignored .runtime directory.
if [ "$(uname -s)" = Darwin ]; then
  HOST_TMP=/private/tmp
else
  HOST_TMP=${TMPDIR:-/tmp}
fi
STAGING_ROOT="$HOST_TMP/nordfracht-soc-$(id -u)"
STAGED_UPSTREAM="$STAGING_ROOT/wazuh-docker"
if [ ! -f "$STAGED_UPSTREAM/single-node/docker-compose.yml" ]; then
  mkdir -p "$STAGING_ROOT"
  cp -R "$UPSTREAM" "$STAGED_UPSTREAM"
fi
cp "$LAB_ROOT/config/local_rules.xml" \
  "$STAGED_UPSTREAM/single-node/config/nordfracht-local-rules.xml"

CERT_DIR="$STAGED_UPSTREAM/single-node/config/wazuh_indexer_ssl_certs"
if [ ! -f "$CERT_DIR/root-ca.pem" ]; then
  docker compose --project-directory "$STAGED_UPSTREAM/single-node" \
    -f "$STAGED_UPSTREAM/single-node/generate-indexer-certs.yml" \
    run --rm generator
fi

"$LAB_ROOT/scripts/lab.sh" up -d --build

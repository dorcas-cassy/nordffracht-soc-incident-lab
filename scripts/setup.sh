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

CERT_DIR="$UPSTREAM/single-node/config/wazuh_indexer_ssl_certs"
if [ ! -f "$CERT_DIR/root-ca.pem" ]; then
  docker compose --project-directory "$UPSTREAM/single-node" \
    -f "$UPSTREAM/single-node/generate-indexer-certs.yml" \
    run --rm generator
fi

"$LAB_ROOT/scripts/lab.sh" up -d --build

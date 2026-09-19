#!/bin/sh
set -eu

LAB_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM="$LAB_ROOT/.runtime/wazuh-docker"

# First-run image downloads need more headroom than a restart with cached images.
# Abort before pulling or starting if the host is too close to full.
FREE_KB=$(df -Pk "$LAB_ROOT" | awk 'NR == 2 { print $4 }')
MIN_FREE_GB=20
if docker image inspect \
  wazuh/wazuh-manager:4.14.7 \
  wazuh/wazuh-indexer:4.14.7 \
  wazuh/wazuh-dashboard:4.14.7 >/dev/null 2>&1; then
  MIN_FREE_GB=10
fi
MIN_FREE_KB=$((MIN_FREE_GB * 1024 * 1024))
if [ -z "$FREE_KB" ] || [ "$FREE_KB" -lt "$MIN_FREE_KB" ]; then
  echo "At least $MIN_FREE_GB GB of free host disk space is required before starting this lab." >&2
  echo 'Free space, then rerun ./scripts/setup.sh.' >&2
  exit 1
fi

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

# This exercise uses SSH and file-integrity alerts, not the vulnerability feed.
# Disable its large background database download in the staged manager config.
MANAGER_CONF="$STAGED_UPSTREAM/single-node/config/wazuh_cluster/wazuh_manager.conf"
sed '/<vulnerability-detection>/,/<\/vulnerability-detection>/ s/<enabled>yes<\/enabled>/<enabled>no<\/enabled>/' \
  "$UPSTREAM/single-node/config/wazuh_cluster/wazuh_manager.conf" > "$MANAGER_CONF"

CERT_DIR="$STAGED_UPSTREAM/single-node/config/wazuh_indexer_ssl_certs"
if [ ! -f "$CERT_DIR/root-ca.pem" ]; then
  docker compose --project-directory "$STAGED_UPSTREAM/single-node" \
    -f "$STAGED_UPSTREAM/single-node/generate-indexer-certs.yml" \
    run --rm generator
fi

"$LAB_ROOT/scripts/lab.sh" up -d --build

#!/bin/sh
set -eu

LAB_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ "$(uname -s)" = Darwin ]; then
  HOST_TMP=/private/tmp
else
  HOST_TMP=${TMPDIR:-/tmp}
fi
STAGING_ROOT="$HOST_TMP/nordfracht-soc-$(id -u)"
UPSTREAM_DIR="$STAGING_ROOT/wazuh-docker/single-node"
LAB_RULES_FILE="$UPSTREAM_DIR/config/nordfracht-local-rules.xml"

if [ ! -f "$UPSTREAM_DIR/docker-compose.yml" ]; then
  echo 'Staged Wazuh files are missing. Run ./scripts/setup.sh first.' >&2
  exit 1
fi

export LAB_ROOT LAB_RULES_FILE
exec docker compose \
  --project-name nordfracht-soc \
  --project-directory "$UPSTREAM_DIR" \
  -f "$UPSTREAM_DIR/docker-compose.yml" \
  -f "$LAB_ROOT/docker-compose.yml" \
  "$@"

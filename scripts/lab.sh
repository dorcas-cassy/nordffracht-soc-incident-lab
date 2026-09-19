#!/bin/sh
set -eu

LAB_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
UPSTREAM_DIR="$LAB_ROOT/.runtime/wazuh-docker/single-node"

if [ ! -f "$UPSTREAM_DIR/docker-compose.yml" ]; then
  echo 'Wazuh upstream files are missing. Run ./scripts/setup.sh first.' >&2
  exit 1
fi

export LAB_ROOT
exec docker compose \
  --project-name nordfracht-soc \
  --project-directory "$UPSTREAM_DIR" \
  -f "$UPSTREAM_DIR/docker-compose.yml" \
  -f "$LAB_ROOT/docker-compose.yml" \
  "$@"

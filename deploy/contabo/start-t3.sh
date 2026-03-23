#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/t3code}"
CURRENT_DIR="${APP_ROOT}/current"

if [[ ! -d "$CURRENT_DIR" ]]; then
  echo "missing deploy directory: $CURRENT_DIR" >&2
  exit 1
fi

HOST_VALUE="${T3CODE_HOST:-}"
if [[ -z "$HOST_VALUE" ]]; then
  HOST_VALUE="$(tailscale ip -4 2>/dev/null | head -n1 || true)"
fi

if [[ -z "$HOST_VALUE" ]]; then
  echo "no bind address available; set T3CODE_HOST or bring up Tailscale" >&2
  exit 1
fi

: "${T3CODE_AUTH_TOKEN:?set T3CODE_AUTH_TOKEN in /opt/t3code/shared/t3code.env}"
: "${T3CODE_PORT:=3773}"
: "${T3CODE_HOME:=${APP_ROOT}/shared/data}"
: "${T3CODE_LOG_LEVEL:=info}"

cd "$CURRENT_DIR"

ARGS=(
  apps/server/dist/index.mjs
  --host "$HOST_VALUE"
  --port "$T3CODE_PORT"
  --home-dir "$T3CODE_HOME"
  --auth-token "$T3CODE_AUTH_TOKEN"
  --no-browser
  --log-level "$T3CODE_LOG_LEVEL"
)

exec node "${ARGS[@]}"

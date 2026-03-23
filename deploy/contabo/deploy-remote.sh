#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/t3code}"
RELEASE_DIR="${1:-$(pwd)}"
SERVICE_PATH="/etc/systemd/system/t3code.service"
ENV_PATH="${APP_ROOT}/shared/t3code.env"

if [[ ! -d "$RELEASE_DIR" ]]; then
  echo "release directory does not exist: $RELEASE_DIR" >&2
  exit 1
fi

cd "$RELEASE_DIR"

command -v bun >/dev/null 2>&1 || {
  echo "bun is required on the VPS" >&2
  exit 1
}

command -v node >/dev/null 2>&1 || {
  echo "node is required on the VPS" >&2
  exit 1
}

mkdir -p "${APP_ROOT}/releases" "${APP_ROOT}/shared/data"

if [[ ! -f "$ENV_PATH" ]]; then
  install -m 600 deploy/contabo/t3code.env.example "$ENV_PATH"
  echo "created ${ENV_PATH}; update it and rerun deploy" >&2
  exit 1
fi

chmod 755 deploy/contabo/start-t3.sh
install -m 644 deploy/contabo/t3code.service "$SERVICE_PATH"

if grep -q '^T3CODE_AUTH_TOKEN=replace-me$' "$ENV_PATH"; then
  echo "replace T3CODE_AUTH_TOKEN in ${ENV_PATH} before deploying" >&2
  exit 1
fi

# Skip workspace prepare hooks on the VPS. They patch editor tooling and have
# already proven expensive enough to be OOM-killed on this host.
bun install --frozen-lockfile --ignore-scripts

# Restore the one native dependency the server needs at runtime.
NODE_PTY_DIR="$(node -p "require('path').dirname(require.resolve('node-pty/package.json', { paths: [require('path').resolve('apps/server')] }))")"
(cd "$NODE_PTY_DIR" && npm run install)

bun run build

ln -sfn "$RELEASE_DIR" "${APP_ROOT}/current"

systemctl daemon-reload
systemctl enable t3code.service
systemctl restart t3code.service

systemctl --no-pager --full status t3code.service

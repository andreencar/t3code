#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

HOST="${1:-contabo-vps}"
APP_ROOT="${APP_ROOT:-/opt/t3code}"
STAMP="$(date -u +%Y%m%d%H%M%S)"
SHA="$(git -C "$REPO_ROOT" rev-parse --short=12 HEAD)"
RELEASE_DIR="${APP_ROOT}/releases/${STAMP}-${SHA}"

if [[ -n "$(git -C "$REPO_ROOT" status --short)" ]]; then
  echo "working tree is dirty; commit or stash before deploying" >&2
  exit 1
fi

echo "Deploying ${SHA} to ${HOST}:${RELEASE_DIR}"

ssh "$HOST" "mkdir -p '${RELEASE_DIR}'"

tar \
  --exclude='.git' \
  --exclude='node_modules' \
  --exclude='.turbo' \
  --exclude='apps/*/node_modules' \
  --exclude='packages/*/node_modules' \
  --exclude='apps/*/dist' \
  --exclude='apps/*/dist-electron' \
  -C "$REPO_ROOT" \
  -czf - . \
  | ssh "$HOST" "tar -xzf - -C '${RELEASE_DIR}'"

ssh "$HOST" "bash '${RELEASE_DIR}/deploy/contabo/deploy-remote.sh' '${RELEASE_DIR}'"

#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${APP_ROOT:-/opt/t3code}"
SHARED_DIR="${APP_ROOT}/shared"
ENV_PATH="${SHARED_DIR}/t3code.env"
SERVICE_PATH="/etc/systemd/system/t3code.service"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

mkdir -p "${APP_ROOT}/releases" "${SHARED_DIR}/data"

if [[ ! -f "$ENV_PATH" ]]; then
  install -m 600 "${REPO_ROOT}/deploy/contabo/t3code.env.example" "$ENV_PATH"
  echo "created ${ENV_PATH} from template"
fi

install -m 644 "${REPO_ROOT}/deploy/contabo/t3code.service" "$SERVICE_PATH"
systemctl daemon-reload
systemctl enable t3code.service

echo "host bootstrap complete"
echo "edit ${ENV_PATH} before first start if it still contains placeholders"

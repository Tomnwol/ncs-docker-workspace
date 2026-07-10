#!/usr/bin/env bash
# Interactive NCS container entrypoint.
# Usage: container-shell.sh <app_name>

set -euo pipefail

APP_NAME="${1:?app name required}"
APPS_DIR="${APPS_DIR:-/apps}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/workspace}"
DEFAULT_BOARD="${DEFAULT_BOARD:?DEFAULT_BOARD is not set}"

export APP_NAME APP_DIR="${APPS_DIR}/${APP_NAME}" BUILD_DIR="${APPS_DIR}/${APP_NAME}/build" DEFAULT_BOARD

cat > "${WORKSPACE_DIR}/commands.txt" <<EOF 
$(printf '\033c')
NCS Docker Workspace
=====================
  ${WORKSPACE_DIR}  SDK workspace (west, zephyr, nrf) — current directory
  ${APPS_DIR}       Your applications

App:    ${APP_NAME}
Board:  ${DEFAULT_BOARD}
Source: ${APP_DIR}
Build:  ${BUILD_DIR}

Run west directly inside the container:

  west build -p always -b ${DEFAULT_BOARD} -d ${BUILD_DIR} ${APP_DIR}
  west flash -r nrfutil -d ${BUILD_DIR}

Or use the exported variables:

  west build -p always -b \$DEFAULT_BOARD -d \$BUILD_DIR \$APP_DIR
  west flash -r nrfutil -d \$BUILD_DIR

EOF

cd "${WORKSPACE_DIR}"
cat "${WORKSPACE_DIR}/commands.txt"
exec bash -l

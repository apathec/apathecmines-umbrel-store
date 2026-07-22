#!/usr/bin/env bash
# ── ApathecMines BCH2 Node — per-install secret generation ───────────────────
# Modelled directly on the BCH2 Forge-Solo exports.sh pattern.
# Umbrel runs exports.sh before starting the app.  We generate a UNIQUE random
# secret per install for every credential and persist them so they are stable
# across restarts.  Nothing is ever hardcoded or shared.
set -eo pipefail
umask 077   # secrets file is created 0600 — no world-readable window
 
# Umbrel does not guarantee APP_DATA_DIR in the exports.sh context and may
# source this script with `set -u` (nounset) active.  exports.sh lives in the
# app data dir, so derive APP_DATA_DIR from this file's own location when
# unset — never abort on an unbound var.
: "${APP_DATA_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)}"
 
APP_SECRETS_FILE="${APP_DATA_DIR}/.secrets.env"
 
if [ ! -f "${APP_SECRETS_FILE}" ]; then
  mkdir -p "${APP_DATA_DIR}"
  gen() { openssl rand -hex 32; }
  {
    echo "APP_BCH2_RPC_USER=apathecpool"
    echo "APP_BCH2_RPC_PASSWORD=$(gen)"
  } > "${APP_SECRETS_FILE}"
  chmod 600 "${APP_SECRETS_FILE}"
fi
 
# shellcheck disable=SC1090
. "${APP_SECRETS_FILE}"
export APP_BCH2_RPC_USER APP_BCH2_RPC_PASSWORD
 
# Compute Base64-encoded "user:pass" for nginx proxy_set_header Authorization
APP_BCH2_RPC_AUTH_B64=$(printf '%s:%s' "${APP_BCH2_RPC_USER}" "${APP_BCH2_RPC_PASSWORD}" | base64 -w0)
export APP_BCH2_RPC_AUTH_B64

#!/usr/bin/env bash
set -euo pipefail

: "${HOSTINGER_USER:?Defina HOSTINGER_USER antes do deploy.}"
: "${HOSTINGER_HOST:?Defina HOSTINGER_HOST antes do deploy.}"

if [[ ! -f build/web/index.html ]]; then
  echo "Build nao encontrada. Rode scripts/build_operational_web.sh primeiro."
  exit 1
fi

remote_path="/home/u165659716/domains/eantrack.com/public_html/operational"
ssh_port_args=()
scp_port_args=()

if [[ -n "${HOSTINGER_PORT:-}" ]]; then
  ssh_port_args=(-p "$HOSTINGER_PORT")
  scp_port_args=(-P "$HOSTINGER_PORT")
fi

ssh "${ssh_port_args[@]}" "${HOSTINGER_USER}@${HOSTINGER_HOST}" "mkdir -p '$remote_path'"
scp "${scp_port_args[@]}" -r build/web/. "${HOSTINGER_USER}@${HOSTINGER_HOST}:${remote_path}/"

echo "Deploy concluido para ${HOSTINGER_USER}@${HOSTINGER_HOST}:${remote_path}/"

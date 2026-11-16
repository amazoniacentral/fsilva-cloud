#!/bin/bash
set -e

# 1. Configurações de Caminho e Rclone
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../../..")             # /opt/fsilva-cloud
RCLONE_CONFIG_HOST="${BASE_DIR}/config/rclone"

# Organização por Data (ex: 2026/11/16)
DATE_PATH=$(date +%Y/%m/%d)
RCLONE_REMOTE="config-crypt:${DATE_PATH}"

echo "===================================================="
echo "Iniciando backup criptografado de configs (.env, .yml, .conf)"
echo "Origem: ${BASE_DIR}"
echo "Destino: ${RCLONE_REMOTE} (Atualiza na pasta do dia)"
echo "===================================================="

# 2. Executa o rclone via Docker com --filter ordenado e flags para evitar erro de chtimes no crypt
docker run --rm \
  --name "rclone_configs_backup" \
  -v "${BASE_DIR}":/data:ro \
  -v "${RCLONE_CONFIG_HOST}":/config/rclone:ro \
  rclone/rclone --config /config/rclone/rclone.conf copy /data "${RCLONE_REMOTE}" \
  --filter "- **/node_modules/**" \
  --filter "+ *.env" \
  --filter "+ *.env.*" \
  --filter "+ *.yml" \
  --filter "+ *.yaml" \
  --filter "+ *.conf" \
  --filter "- *" \
  --fast-list \
  --buffer-size 16M \
  --transfers 2 \
  --checkers 4 \
  --no-update-modtime \
  --progress

echo "✅ Backup concluído na pasta diária ${RCLONE_REMOTE} do R2!"

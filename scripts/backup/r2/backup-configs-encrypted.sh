#!/bin/bash
set -e

# 1. Configurações de Caminho e Rclone
BASE_DIR="/opt/fsilva-cloud"
RCLONE_CONFIG_HOST="${BASE_DIR}/config/rclone"
RCLONE_REMOTE="r2-crypt:fsilva-cloud/configs"

echo "===================================================="
echo "Iniciando backup criptografado de configs (.env, .yml, .conf)"
echo "Origem: ${BASE_DIR}"
echo "Destino: ${RCLONE_REMOTE}"
echo "===================================================="

# 2. Executa o rclone via Docker filtrando apenas os arquivos permitidos (sem Dockerfile e .md)
docker run --rm \
  --name "rclone_configs_backup" \
  -v "${BASE_DIR}":/data:ro \
  -v "${RCLONE_CONFIG_HOST}":/config/rclone \
  rclone/rclone --config /config/rclone/rclone.conf copy /data "${RCLONE_REMOTE}" \
  --include "*.env" \
  --include "*.env.*" \
  --include "*.yml" \
  --include "*.yaml" \
  --include "*.conf" \
  --exclude "**" \
  --fast-list \
  --buffer-size 16M \
  --transfers 2 \
  --checkers 4 \
  --progress

echo "✅ Backup de configurações concluído e enviado criptografado para o R2!"

#!/bin/bash
set -e

# 1. Configurações de Caminho e Rclone
BASE_DIR="/opt/fsilva-cloud"
RCLONE_CONFIG_HOST="${BASE_DIR}/config/rclone"
RCLONE_REMOTE="r2-crypt:fsilva-cloud/configs"

echo "===================================================="
echo "Iniciando restauração e descriptografia de configs"
echo "Origem: ${RCLONE_REMOTE}"
echo "Destino: ${BASE_DIR}"
echo "===================================================="

# 2. Executa o rclone via Docker para baixar e descriptografar de volta para a pasta
docker run --rm \
  --name "rclone_configs_restore" \
  -v "${BASE_DIR}":/data \
  -v "${RCLONE_CONFIG_HOST}":/config/rclone \
  rclone/rclone --config /config/rclone/rclone.conf copy "${RCLONE_REMOTE}" /data \
  --fast-list \
  --buffer-size 16M \
  --transfers 2 \
  --checkers 4 \
  --progress

echo "✅ Restauração e descriptografia de configurações concluídas com sucesso!"

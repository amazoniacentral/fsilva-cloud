#!/bin/bash

# 1. Ajuste de Caminhos (Baseado na estrutura real da sua VPS)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Sobe um nível para /opt/fsilva-cloud
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")

# Onde o seu rclone.conf REALMENTE está
RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"
DEST="gvendas:backup_sgn"
# Garante que a pasta de logs existe
mkdir -p "$BASE_DIR/logs"

echo "-------------------------------------------"
echo "BACKUP DE DADOS"
echo "-------------------------------------------"
echo "--- Backup Iniciado: $(date) ---"

# 2. Executa o container
# Ajustamos os volumes para não tentar criar pastas dentro do container (evita o erro read-only)
docker run --rm \
  --name rclone_backup_worker \
  -v "backups":/data/backups:ro \
  -v "storage_data":/data/documentos:ro \
  -v "media_data":/data/arquivos:ro \
  -v "$RCLONE_CONFIG_HOST":/config/rclone \
  rclone/rclone --config /config/rclone/rclone.conf copy /data $DEST \
  --use-server-modtime \
  --buffer-size 32M

echo "--- Backup Finalizado: $(date) ---"

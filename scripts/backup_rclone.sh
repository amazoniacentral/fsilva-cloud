#!/bin/bash

# Pega o diretório onde o script está e sobe um nível para a raiz do projeto
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../rclone")

RCLONE_CONFIG="$BASE_DIR/config/rclone"
LOG_FILE="$BASE_DIR/logs/backup_rclone.log"

# Garante que a pasta de logs existe
mkdir -p "$BASE_DIR/logs"

echo "--- Backup Iniciado: $(date) ---" >> "$LOG_FILE"

# Executa o container efêmero (nasce, faz o sync e morre)
docker run --rm \
  --name rclone_backup_worker \
  -v "backups":/data:ro \
  -v "storage_data":/data/documentos:ro \
  -v "media_data":/data/arquivos:ro \
  -v "$RCLONE_CONFIG":/config/rclone \
  rclone/rclone copy /data gdrive:backup_sgn \
  --use-server-modtime \
  >> "$LOG_FILE" 2>&1

echo "--- Backup Finalizado: $(date) ---" >> "$LOG_FILE"

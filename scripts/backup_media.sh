#!/bin/bash

# Pega os caminhos automáticos
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/..")

# Configurações
SOURCE="$CD_DIR/sgn_media"
DEST="gdrive:backup_vendas/media"
LOG_FILE="$CD_DIR/logs/rclone.log"

mkdir -p "$(dirname "$LOG_FILE")"

echo "Iniciando sincronização: $(date)" >> "$LOG_FILE"

# O comando 'sync' faz o destino ficar IGUAL à origem
# Se você deletar na VPS, deleta no Drive. Se quiser apenas copiar, use 'copy'
rclone sync "$SOURCE" "$DEST" --vfs-cache-mode writes >> "$LOG_FILE" 2>&1

echo "Sincronização finalizada: $(date)" >> "$LOG_FILE"

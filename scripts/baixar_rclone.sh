#!/bin/bash

# 1. Ajuste de Caminhos
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")

# Nome do projeto
PROJECT_NAME="fsilva-cloud-dev"

# Onde o seu rclone.conf está
RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

# ORIGEM (Nuvem) e DESTINO (Container)
SRC="gvendas:${PROJECT_NAME}"

# Garante que a pasta de logs existe
mkdir -p "$BASE_DIR/logs"

echo "-------------------------------------------"
echo "DOWNLOAD DE DADOS (RESTORE) - PROJETO: $PROJECT_NAME"
echo "-------------------------------------------"
echo "--- Download Iniciado: $(date '+%Y-%m-%d %H:%M:%S') ---"

# 2. Executa o container rclone para BAIXAR os dados
# Note que os volumes NÃO possuem :ro para permitir escrita
docker run --rm \
  --name rclone_restore_worker \
  -v "${PROJECT_NAME}_catalogos_pdf_data":/data \
  -v "$RCLONE_CONFIG_HOST":/config/rclone \
  rclone/rclone --config /config/rclone/rclone.conf copy $SRC/catalogos /data \
  --use-server-modtime \
  --buffer-size 32M \
  --transfers 4 \
  --checkers 8 \
  --contimeout 60s \
  --low-level-retries 10 \
  -v

echo "--- Download Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"

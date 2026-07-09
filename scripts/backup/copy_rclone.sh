#!/bin/bash

# 1. Ajuste de Caminhos
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../..")

PROJECTS=$(
  docker ps --filter "label=com.docker.compose.project" --format '{{.Label "com.docker.compose.project"}}' |
  sort -u
)

echo "Projetos encontrados:"
echo "$PROJECTS"
for PROJECT_NAME in $PROJECTS; do

    echo
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="


    # Nome do projeto definido no seu docker-compose.dev.yml
    #PROJECT_NAME="fsilva-cloud-dev"

    # Onde o seu rclone.conf REALMENTE está
    RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"
    SRC="gdrive:fsilva-cloud/${PROJECT_NAME}"
    #DEST="gdrive:${PROJECT_NAME}"

    # Garante que a pasta de logs existe
    mkdir -p "$BASE_DIR/logs"

    echo "-------------------------------------------"
    echo "BACKUP DE DADOS - PROJETO: $PROJECT_NAME"
    echo "-------------------------------------------"
    echo "--- Backup Iniciado: $(date '+%Y-%m-%d %H:%M:%S') ---"

    # 2. Executa o container apontando para os volumes do projeto
    # O Docker Compose nomeia volumes como: [PROJECT_NAME]_[VOLUME_NAME]
    docker run --rm \
      --name rclone_backup_worker \
      -v "${PROJECT_NAME}_backups":/data/database:ro \
      -v "${PROJECT_NAME}_storage_data":/data/documentos:ro \
      -v "${PROJECT_NAME}_media_data":/data/arquivos:ro \
      -v "${PROJECT_NAME}_catalogos_pdf_compress_data":/data/catalogos/compress:ro \
      -v "$RCLONE_CONFIG_HOST":/config/rclone \
      rclone/rclone --config /config/rclone/rclone.conf copy /data $SRC \
      --use-server-modtime \
      --buffer-size 16M \
      --bwlimit 2M \
      --transfers 2 \
      --checkers 4 \
      --contimeout 60s \
      --low-level-retries 10

echo "--- Backup Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"

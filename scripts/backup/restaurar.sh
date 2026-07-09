#!/bin/bash

# 1. Ajuste de Caminhos
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../..")

# Configurações globais
RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

# Garante que a pasta de logs existe (fora do loop, pois só precisa rodar uma vez)
mkdir -p "$BASE_DIR/logs"

# Busca nomes dos projetos via labels do Docker Compose
PROJECTS=$(
  docker ps --filter "label=com.docker.compose.project" --format '{{.Label "com.docker.compose.project"}}' |
  sort -u
)

echo "Projetos encontrados:"
echo "$PROJECTS"

# Itera sobre cada projeto de forma segura
echo "$PROJECTS" | while read -r PROJECT_NAME; do

    # Pula linhas vazias se houver
    [ -z "$PROJECT_NAME" ] && continue

    echo
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="

    SRC="gdrive:fsilva-cloud/${PROJECT_NAME}"

    echo "-------------------------------------------"
    echo "RESTAURAR DADOS - PROJETO: $PROJECT_NAME"
    echo "-------------------------------------------"
    echo "--- Restauração Iniciada: $(date '+%Y-%m-%d %H:%M:%S') ---"

    # 2. Executa o container apontando para os volumes do projeto
    # Nome do container dinamizado com $PROJECT_NAME para evitar conflito de nomes
    docker run --rm \
      --name "rclone_backup_${PROJECT_NAME}" \
      -v "${PROJECT_NAME}_backups":/data/database \
      -v "${PROJECT_NAME}_storage_data":/data/documentos \
      -v "${PROJECT_NAME}_media_data":/data/arquivos \
      -v "${PROJECT_NAME}_catalogos_pdf_compress_data":/data/catalogos/compress \
      -v "$RCLONE_CONFIG_HOST":/config/rclone \
      rclone/rclone --config /config/rclone/rclone.conf sync "$SRC" /data \
      --use-server-modtime \
      --buffer-size 16M \
      --bwlimit 2M \
      --transfers 2 \
      --checkers 4 \
      --contimeout 60s \
      --low-level-retries 10

    echo "--- Restauração Finalizado para $PROJECT_NAME: $(date '+%Y-%m-%d %H:%M:%S') ---"

done

echo
echo "==========================================="
echo "TODOS OS BACKUPS FORAM RESTAURADOS!"
echo "==========================================="

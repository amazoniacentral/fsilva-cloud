#!/bin/bash
set -e

# 1. Ajuste de Caminhos
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../..")

# Configurações globais
RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

# IMPORTANTE: Usando o remote dedicado 'volumes-crypt' que aponta para o bucket 'volumes'
RCLONE_REMOTE="volumes-crypt:"

# Garante que a pasta de logs existe
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

    # Destino criptografado no bucket 'volumes' via volumes-crypt
    DEST="${RCLONE_REMOTE}${PROJECT_NAME}"

    echo "-------------------------------------------"
    echo "BACKUP R2 (CRIPTOGRAFADO) - PROJETO: $PROJECT_NAME"
    echo "-------------------------------------------"
    echo "--- Backup Iniciado: $(date '+%Y-%m-%d %H:%M:%S') ---"

    # 2. Executa o container do rclone mapeando os volumes do projeto como leitura (ro)
    docker run --rm \
      --name "rclone_r2_backup_${PROJECT_NAME}" \
      -v "${PROJECT_NAME}_storage_data":/data/documentos:ro \
      -v "${PROJECT_NAME}_media_data":/data/arquivos:ro \
      -v "${PROJECT_NAME}_catalogos_pdf_compress_data":/data/catalogos:ro \
      -v "$RCLONE_CONFIG_HOST":/config/rclone \
      rclone/rclone --config /config/rclone/rclone.conf copy /data "$DEST" \
      --use-server-modtime \
      --buffer-size 16M \
      --bwlimit 2M \
      --transfers 2 \
      --checkers 4 \
      --contimeout 60s \
      --low-level-retries 10

    echo "--- Backup para o R2 Finalizado para $PROJECT_NAME: $(date '+%Y-%m-%d %H:%M:%S') ---"

done

echo
echo "==========================================="
echo "TODOS OS BACKUPS DE VOLUMES PARA O R2 FORAM CONCLUÍDOS!"
echo "==========================================="

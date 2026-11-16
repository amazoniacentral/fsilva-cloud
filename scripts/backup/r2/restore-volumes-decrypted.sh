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

# Itera sobre cada projeto de forma segura (usando heredoc para evitar subshell)
while read -r PROJECT_NAME; do

    # Pula linhas vazias se houver
    [ -z "$PROJECT_NAME" ] && continue

    echo
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="

    # Origem criptografada no bucket 'volumes' via volumes-crypt
    SRC="${RCLONE_REMOTE}${PROJECT_NAME}"

    echo "-------------------------------------------"
    echo "RESTAURAÇÃO R2 (VOLUMES) - PROJETO: $PROJECT_NAME"
    echo "-------------------------------------------"
    echo "--- Restauração Iniciada: $(date '+%Y-%m-%d %H:%M:%S') ---"

    # Garante que os volumes locais do projeto existam antes de montar
    docker volume create "${PROJECT_NAME}_storage_data" >/dev/null 2>&1
    docker volume create "${PROJECT_NAME}_media_data" >/dev/null 2>&1

    # 2. Executa o container do rclone mapeando APENAS storage_data e media_data
    docker run --rm \
      --name "rclone_r2_restore_${PROJECT_NAME}" \
      -v "${PROJECT_NAME}_storage_data":/data/storage_data \
      -v "${PROJECT_NAME}_media_data":/data/media_data \
      -v "$RCLONE_CONFIG_HOST":/config/rclone \
      rclone/rclone --config /config/rclone/rclone.conf sync "$SRC" /data \
      --include "storage_data/**" \
      --include "media_data/**" \
      --exclude "**" \
      --use-server-modtime \
      --delete-during \
      --buffer-size 16M \
      --bwlimit 2M \
      --transfers 2 \
      --checkers 4 \
      --contimeout 60s \
      --low-level-retries 10 \
      --progress

    echo "--- Restauração do R2 Finalizada para $PROJECT_NAME: $(date '+%Y-%m-%d %H:%M:%S') ---"

done <<< "$PROJECTS"

echo
echo "==========================================="
echo "TODAS AS RESTAURAÇÕES DE VOLUMES DO R2 FORAM CONCLUÍDAS!"
echo "==========================================="

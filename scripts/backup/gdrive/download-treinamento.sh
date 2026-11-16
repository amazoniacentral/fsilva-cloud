#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../../..")

RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

mkdir -p "$BASE_DIR/logs"

echo "-------------------------------------------"
echo "ESPELHAMENTO DE TREINAMENTO IA (DRIVE -> SERVIDOR)"
echo "-------------------------------------------"
echo "--- Iniciado: $(date '+%Y-%m-%d %H:%M:%S') ---"

PROJECTS=$(
docker volume ls --format '{{.Name}}' |
grep '_treinamento_ia$' |
sed 's/_treinamento_ia$//' |
sort -u
)

echo "Projetos encontrados:"
echo "$PROJECTS"

for PROJECT_NAME in $PROJECTS; do

    echo
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="

    TREINAMENTO_VOLUME="${PROJECT_NAME}_treinamento_ia"

    if ! docker volume inspect "$TREINAMENTO_VOLUME" >/dev/null 2>&1; then
        echo "Volume de treinamento não encontrado: $TREINAMENTO_VOLUME"
        continue
    fi

    SRC="gdrive:fsilva-cloud/${PROJECT_NAME}"

    # ESPELHAR: Google Drive (Origem) -> Volume Local (Destino)
    echo "Espelhando treinamento IA para o volume ${TREINAMENTO_VOLUME}..."
    docker run --rm \
        --name "rclone_sync_${PROJECT_NAME}_treinamento" \
        -v "${TREINAMENTO_VOLUME}:/data/treinamento-ia" \
        -v "$RCLONE_CONFIG_HOST:/config/rclone:ro" \
        rclone/rclone \
        sync "$SRC/treinamento-ia" /data/treinamento-ia \
        --config /config/rclone/rclone.conf \
        --use-server-modtime \
        --delete-during \
        --buffer-size 32M \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --low-level-retries 10 \
        -v

    echo "✓ Espelhamento do treinamento IA concluído para $PROJECT_NAME"

done

echo
echo "--- Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"

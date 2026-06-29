#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../..")

RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

mkdir -p "$BASE_DIR/logs"

echo "-------------------------------------------"
echo "SINCRONIZAÇÃO DE TODOS OS PROJETOS"
echo "-------------------------------------------"
echo "--- Iniciado: $(date '+%Y-%m-%d %H:%M:%S') ---"

PROJECTS=$(
docker volume ls --format '{{.Name}}' |
grep '_catalogos_pdf_data$' |
sed 's/_catalogos_pdf_data$//' |
sort -u
)

echo "Projetos encontrados:"
echo "$PROJECTS"

for PROJECT_NAME in $PROJECTS; do

    echo
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="

    CATALOGO_VOLUME="${PROJECT_NAME}_catalogos_pdf_data"
    TREINAMENTO_VOLUME="${PROJECT_NAME}_treinamento_ia"

    if ! docker volume inspect "$CATALOGO_VOLUME" >/dev/null 2>&1; then
        echo "Volume catálogo não encontrado: $CATALOGO_VOLUME"
        continue
    fi

    SRC="gdrive:fsilva-cloud/${PROJECT_NAME}"

    # CATÁLOGO
    docker run --rm \
        --name "rclone_sync_${PROJECT_NAME}_catalogos" \
        -v "${CATALOGO_VOLUME}:/data/catalogos" \
        -v "$RCLONE_CONFIG_HOST:/config/rclone:ro" \
        rclone/rclone \
        sync "$SRC/catalogos/bruto" /data/catalogos \
        --config /config/rclone/rclone.conf \
        --use-server-modtime \
        --delete-during \
        --buffer-size 32M \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --low-level-retries 10 \
        -v

    # TREINAMENTO (se existir)
    if docker volume inspect "$TREINAMENTO_VOLUME" >/dev/null 2>&1; then

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
    else
        echo "Volume treinamento não encontrado (ignorando)"
    fi

    echo "✓ Sync concluído para $PROJECT_NAME"

done

echo
echo "--- Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"
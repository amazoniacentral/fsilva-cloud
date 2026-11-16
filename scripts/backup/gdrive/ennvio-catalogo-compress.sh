#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../../..")

RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

mkdir -p "$BASE_DIR/logs"

echo "-------------------------------------------"
echo "ENVIO DE CATÁLOGOS COMPRESS PARA O GOOGLE DRIVE"
echo "-------------------------------------------"
echo "--- Iniciado: $(date '+%Y-%m-%d %H:%M:%S') ---"

PROJECTS=$(
docker volume ls --format '{{.Name}}' |
grep '_catalogos_pdf_compress_data$' |
sed 's/_catalogos_pdf_compress_data$//' |
sort -u
)

echo "Projetos encontrados:"
echo "$PROJECTS"

for PROJECT_NAME in $PROJECTS; do

    echo
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="

    CATALOGO_VOLUME="${PROJECT_NAME}_catalogos_pdf_compress_data"

    if ! docker volume inspect "$CATALOGO_VOLUME" >/dev/null 2>&1; then
        echo "Volume de compressão não encontrado: $CATALOGO_VOLUME"
        continue
    fi

    SRC="gdrive:fsilva-cloud/${PROJECT_NAME}"

    # ENVIAR (UPLOAD): Servidor Local -> Google Drive (Espelho exato)
    echo "Enviando catálogo compress para o Google Drive..."
    docker run --rm \
        --name "rclone_sync_${PROJECT_NAME}_compress" \
        -v "${CATALOGO_VOLUME}:/data/compress" \
        -v "$RCLONE_CONFIG_HOST:/config/rclone:ro" \
        rclone/rclone \
        sync /data/compress "$SRC/catalogos/compress" \
        --config /config/rclone/rclone.conf \
        --use-server-modtime \
        --delete-during \
        --buffer-size 32M \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --low-level-retries 10 \
        -v

    echo "✓ Envio do catálogo compress concluído para $PROJECT_NAME"

done

echo
echo "--- Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"

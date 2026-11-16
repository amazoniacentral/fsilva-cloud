#!/bin/bash

set -e

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../../..")

RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

mkdir -p "$BASE_DIR/logs"

echo "-------------------------------------------"
echo "ESPELHAMENTO DE CATÁLOGOS BRUTOS (APENAS PDF) (DRIVE -> SERVIDOR)"
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

    if ! docker volume inspect "$CATALOGO_VOLUME" >/dev/null 2>&1; then
        echo "Volume catálogo não encontrado: $CATALOGO_VOLUME"
        continue
    fi

    SRC="gdrive:fsilva-cloud/${PROJECT_NAME}"

    # BLINDAGEM DO HOST: Cria cópia temporária da config do rclone isolada em /tmp
    TEMP_CONFIG_DIR=$(mktemp -d)
    cp "$RCLONE_CONFIG_HOST/rclone.conf" "$TEMP_CONFIG_DIR/rclone.conf"

    # ESPELHAR: Google Drive (Origem) -> Volume Local (Destino) [Apenas PDFs com --filter]
    echo "Espelhando apenas arquivos PDF do catálogo bruto para o volume ${CATALOGO_VOLUME}..."
    docker run --rm \
        --name "rclone_sync_${PROJECT_NAME}_catalogos" \
        -v "${CATALOGO_VOLUME}:/data/catalogos" \
        -v "$TEMP_CONFIG_DIR:/config/rclone" \
        rclone/rclone \
        sync "$SRC/catalogos/bruto" /data/catalogos \
        --config /config/rclone/rclone.conf \
        --filter "+ *.pdf" \
        --filter "- *" \
        --use-server-modtime \
        --delete-during \
        --buffer-size 32M \
        --transfers 4 \
        --checkers 8 \
        --contimeout 60s \
        --low-level-retries 10 \
        -v

    # Remove a pasta temporária após o uso
    rm -rf "$TEMP_CONFIG_DIR"

    echo "✓ Espelhamento dos PDFs do catálogo bruto concluído para $PROJECT_NAME"

done

echo
echo "--- Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"

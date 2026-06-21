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

# Descobre os projetos pelos volumes existentes
PROJECTS=$(
docker volume ls --format '{{.Name}}' |
grep '_catalogos_pdf_data$' |
sed 's/_catalogos_pdf_data$//' |
sort -u
)

if [ -z "$PROJECTS" ]; then
    echo "Nenhum projeto encontrado."
    exit 1
fi

echo "Projetos encontrados:"
echo "$PROJECTS"

for PROJECT_NAME in $PROJECTS; do

    echo
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="

    CATALOGO_VOLUME="${PROJECT_NAME}_catalogos_pdf_data"

    # Procura automaticamente um volume de treinamento do projeto
    TREINAMENTO_VOLUME=$(
        docker volume ls --format '{{.Name}}' |
        grep "^${PROJECT_NAME}_" |
        grep 'treinamento'
    )

    if [ -z "$TREINAMENTO_VOLUME" ]; then
        echo "Volume de treinamento não encontrado para $PROJECT_NAME"
        continue
    fi

    SRC="gvendas:fsilva-cloud/${PROJECT_NAME}"

    docker run --rm \
        --name "rclone_sync_${PROJECT_NAME}" \
        -v "${CATALOGO_VOLUME}:/data/catalogos" \
        -v "${TREINAMENTO_VOLUME}:/data/treinamento-ia" \
        -v "$RCLONE_CONFIG_HOST:/config/rclone:ro" \
        rclone/rclone \
        sh -c "
            rclone --config /config/rclone/rclone.conf sync \
                '$SRC/catalogos/bruto' \
                /data/catalogos \
                --use-server-modtime \
                --delete-during \
                --buffer-size 32M \
                --transfers 4 \
                --checkers 8 \
                --contimeout 60s \
                --low-level-retries 10 \
                -v &&

            rclone --config /config/rclone/rclone.conf sync \
                '$SRC/treinamento-ia' \
                /data/treinamento-ia \
                --use-server-modtime \
                --delete-during \
                --buffer-size 32M \
                --transfers 4 \
                --checkers 8 \
                --contimeout 60s \
                --low-level-retries 10 \
                -v
        "

    echo "✓ Sync concluído para $PROJECT_NAME"

done

echo
echo "--- Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"
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

    # BLINDAGEM DO HOST: Copia o master para uma pasta temporária isolada (/tmp)
    TEMP_CONFIG_DIR=$(mktemp -d)
    cp "$RCLONE_CONFIG_HOST/rclone.conf" "$TEMP_CONFIG_DIR/rclone.conf"

    # ESPELHAR: Google Drive (Origem) -> Volume Local (Destino)
    # O rclone atualiza o token na cópia em /tmp, mantendo o host intacto
    echo "Espelhando treinamento IA para o volume ${TREINAMENTO_VOLUME}..."
    docker run --rm \
        --name "rclone_sync_${PROJECT_NAME}_treinamento" \
        -v "${TREINAMENTO_VOLUME}:/data/treinamento-ia" \
        -v "$TEMP_CONFIG_DIR:/config/rclone" \
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

    # Remove a pasta temporária para não deixar lixo na VPS
    rm -rf "$TEMP_CONFIG_DIR"

    echo "✓ Espelhamento do treinamento IA concluído para $PROJECT_NAME"

done

echo
echo "--- Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"

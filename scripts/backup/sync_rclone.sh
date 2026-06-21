#!/bin/bash

set -e

# Diretório do script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../..")

# Onde está o rclone.conf
RCLONE_CONFIG_HOST="$BASE_DIR/config/rclone"

# Garante a pasta de logs
mkdir -p "$BASE_DIR/logs"

echo "-------------------------------------------"
echo "SINCRONIZAÇÃO DE TODOS OS PROJETOS"
echo "-------------------------------------------"
echo "--- Iniciado: $(date '+%Y-%m-%d %H:%M:%S') ---"

# Busca todos os nomes de projetos declarados nos arquivos yml/yaml
PROJECTS=$(
find "$BASE_DIR" -type f \( \
    -name "*.yml" -o \
    -name "*.yaml" \
\) -exec grep -hE '^[[:space:]]*name:' {} \; |
sed -E 's/^[[:space:]]*name:[[:space:]]*//' |
sort -u
)

if [ -z "$PROJECTS" ]; then
    echo "Nenhum projeto encontrado."
    exit 1
fi

echo "Projetos encontrados:"
echo "$PROJECTS"

for PROJECT_NAME in $PROJECTS; do

    echo ""
    echo "==========================================="
    echo "PROJETO: $PROJECT_NAME"
    echo "==========================================="

    CATALOGO_VOLUME="${PROJECT_NAME}_catalogos_pdf_data"
    TREINAMENTO_VOLUME="${PROJECT_NAME}_treinamento-ia"

    # Evita criar volumes como root caso ainda não existam
    if ! docker volume inspect "$CATALOGO_VOLUME" >/dev/null 2>&1; then
        echo "Volume não encontrado: $CATALOGO_VOLUME"
        continue
    fi

    if ! docker volume inspect "$TREINAMENTO_VOLUME" >/dev/null 2>&1; then
        echo "Volume não encontrado: $TREINAMENTO_VOLUME"
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

echo ""
echo "--- Finalizado: $(date '+%Y-%m-%d %H:%M:%S') ---"
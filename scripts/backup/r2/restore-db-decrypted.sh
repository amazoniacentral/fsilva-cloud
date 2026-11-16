#!/bin/bash

# 1. Configurações de Caminho e Rclone
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../../..")
RCLONE_CONFIG_HOST="${BASE_DIR}/config/rclone"

# IMPORTANTE: Usamos o remote criptografado como origem. 
# O rclone vai ler do R2, descriptografar sozinho e entregar os arquivos limpos.
RCLONE_REMOTE="r2-crypt:fsilva-cloud/database"

# 2. Busca TODOS os containers Postgres rodando para identificar os projetos ativos
CONTAINERS_POSTGRES=$(docker ps --filter "name=postgres" --filter "status=running" --format "{{.Names}}")

if [ -z "$CONTAINERS_POSTGRES" ]; then
    echo "Erro: Nenhum container Postgres encontrado para associar aos projetos."
    exit 1
fi

echo "Iniciando o download e descriptografia dos backups do Cloudflare R2..."

# Loop para processar cada projeto encontrado
for CONTAINER_DB_ALVO in $CONTAINERS_POSTGRES; do
    echo "-------------------------------------------"
    echo "PROCESSANDO PROJETO DO CONTAINER: $CONTAINER_DB_ALVO"

    # 3. Identificação Automática do Projeto Compose via Label
    PROJECT_NAME=$(docker inspect "$CONTAIN_DB_ALVO" \
        --format='{{index .Config.Labels "com.docker.compose.project"}}' | tr -d '\r')

    if [ -z "$PROJECT_NAME" ]; then
        echo "Aviso: Container '$CONTAINER_DB_ALVO' não possui label de projeto. Pulando..."
        continue
    fi

    VOLUME_BACKUP_COMPETE="${PROJECT_NAME}_backups"
    echo "Projeto: $PROJECT_NAME | Volume local: $VOLUME_BACKUP_COMPETE"

    # Garante que o volume local do projeto existe; se não existir, cria
    if ! docker volume inspect "$VOLUME_BACKUP_COMPETE" >/dev/null 2>&1; then
        echo "Criando volume local ausente: $VOLUME_BACKUP_COMPETE"
        docker volume create "$VOLUME_BACKUP_COMPETE"
    fi

    # 4. Download e Descriptografia Automática via Rclone (Direto para o Volume Local)
    echo " -> Baixando e descriptografando arquivos do R2..."
    docker run --rm \
      --name "rclone_db_download_${PROJECT_NAME}" \
      -v "${VOLUME_BACKUP_COMPETE}":/data \
      -v "$RCLONE_CONFIG_HOST":/config/rclone \
      rclone/rclone --config /config/rclone/rclone.conf copy "${RCLONE_REMOTE}/${PROJECT_NAME}" /data \
      --fast-list \
      --buffer-size 16M \
      --transfers 2 \
      --checkers 4 \
      --progress

    if [ $? -eq 0 ]; then
        echo "    Download e descriptografia concluídos com sucesso para: $PROJECT_NAME"
    else
        echo "    Erro ao baixar/descriptografar backups para: $PROJECT_NAME"
    fi

done

echo "-------------------------------------------"
echo "Processo de Download e Descriptografia Finalizado: $(date '+%Y-%m-%d %H:%M:%S')"
echo "-------------------------------------------"

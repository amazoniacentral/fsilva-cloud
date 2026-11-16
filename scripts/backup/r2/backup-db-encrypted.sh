#!/bin/bash

# 1. Configurações de Caminho e Rclone
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../../..")             # Ajuste conforme a estrutura do seu VPS (ex: /opt/fsilva-cloud)
RCLONE_CONFIG_HOST="${BASE_DIR}/config/rclone"          # Caminho onde fica o seu rclone.conf

# IMPORTANTE: Use aqui o nome do seu remote criptografado (ex: r2-crypt) configurado no rclone.conf
RCLONE_REMOTE="r2-crypt:fsilva-cloud/database"

# 2. Busca TODOS os containers Postgres rodando
CONTAINERS_POSTGRES=$(docker ps --filter "name=postgres" --filter "status=running" --format "{{.Names}}")

if [ -z "$CONTAINERS_POSTGRES" ]; then
    echo "Erro: Nenhum container Postgres encontrado."
    exit 1
fi

echo "Iniciando backup em massa do PostgreSQL e envio criptografado para o R2..."

# Loop para processar cada container encontrado
for CONTAINER_DB_ALVO in $CONTAINERS_POSTGRES; do
    echo "-------------------------------------------"
    echo "PROCESSANDO: $CONTAINER_DB_ALVO"

    # 3. Identificação Automática do Projeto Compose via Label
    PROJECT_NAME=$(docker inspect "$CONTAINER_DB_ALVO" \
        --format='{{index .Config.Labels "com.docker.compose.project"}}' | tr -d '\r')

    # Se não houver projeto associado, pula para o próximo container
    if [ -z "$PROJECT_NAME" ]; then
        echo "Aviso: Container '$CONTAINER_DB_ALVO' não possui label de projeto. Pulando..."
        continue
    fi

    # 4. Nome do Volume baseado no Projeto
    VOLUME_BACKUP_COMPETE="${PROJECT_NAME}_backups"

    # Formato de pasta para organização: YYYY/MM
    DATA_PASTA=$(date +%Y/%m)

    # 5. Extração do Usuário Administrador
    DB_USER=$(docker inspect "$CONTAINER_DB_ALVO" \
        --format='{{range .Config.Env}}{{println .}}{{end}}' \
        | grep "^POSTGRES_USER=" \
        | cut -d'=' -f2 | tr -d '\r')

    DB_USER=${DB_USER:-postgres}

    # 6. Listagem de Bancos de Dados
    BANCOS=$(docker exec -i "$CONTAINER_DB_ALVO" \
        psql -U "$DB_USER" -d postgres -t -A -c \
        "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

    echo "Projeto: $PROJECT_NAME | Volume: $VOLUME_BACKUP_COMPETE"

    if [ -z "$BANCOS" ]; then
        echo " -> Nenhum banco personalizado encontrado."
        continue
    fi

    for DB in $BANCOS; do
        DB=$(echo "$DB" | xargs | tr -d '\r')
        [ -z "$DB" ] && continue

        echo " -> Fazendo dump local do banco: $DB"

        # Garante que a pasta de destino do backup exista dentro do volume local
        PASTA_DESTINO="/var/lib/docker/volumes/${VOLUME_BACKUP_COMPETE}/_data/${DB}/${DATA_PASTA}"
        mkdir -p "$PASTA_DESTINO"

        # 7. Executa o pg_dump compactado diretamente de dentro do container
        docker exec -i "$CONTAINER_DB_ALVO" pg_dump \
            -U "$DB_USER" \
            -d "$DB" \
            -F c \
            -Z 9 \
            -b > "$PASTA_DESTINO/${DB}-${CONTAINER_DB_ALVO}-$(date +%Y-%m-%d)-$(date +%H%M).backup"

        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo "    Backup local concluído com sucesso: $DB"
        else
            echo "    Erro ao fazer backup local: $DB"
        fi
    done

    # 8. Envio 100% Criptografado para o Cloudflare R2 via Rclone (Docker Container)
    echo " -> Enviando backups criptografados para o Cloudflare R2..."
    if docker volume inspect "$VOLUME_BACKUP_COMPETE" >/dev/null 2>&1; then
        docker run --rm \
          --name "rclone_db_upload_${PROJECT_NAME}" \
          -v "${VOLUME_BACKUP_COMPETE}":/data:ro \
          -v "$RCLONE_CONFIG_HOST":/config/rclone \
          rclone/rclone --config /config/rclone/rclone.conf copy /data "${RCLONE_REMOTE}/${PROJECT_NAME}" \
          --fast-list \
          --buffer-size 16M \
          --transfers 2 \
          --checkers 4
        echo "    Upload criptografado para o R2 concluído!"
    else
        echo "    Aviso: Volume ${VOLUME_BACKUP_COMPETE} não encontrado para upload."
    fi

    # 9. Limpeza de backups antigos locais (+180 dias)
    echo " -> Executando limpeza local de backups antigos (+180 dias)..."
    TARGET_VOL_DIR="/var/lib/docker/volumes/${VOLUME_BACKUP_COMPETE}/_data"
    if [ -d "$TARGET_VOL_DIR" ]; then
        find "$TARGET_VOL_DIR" -type f -mtime +180 -name '*.backup' -exec rm -f {} + 2>/dev/null
        find "$TARGET_VOL_DIR" -type d -empty -not -path "$TARGET_VOL_DIR" -exec rmdir -p {} + 2>/dev/null
    fi

done

echo "-------------------------------------------"
echo "Processo de Backup e Criptografia Finalizado: $(date '+%Y-%m-%d %H:%M:%S')"
echo "-------------------------------------------"

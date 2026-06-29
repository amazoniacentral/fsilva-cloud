#!/bin/bash

# 1. Busca TODOS os containers Postgres rodando
CONTAINERS_POSTGRES=$(docker ps --filter "name=postgres" --filter "status=running" --format "{{.Names}}")

if [ -z "$CONTAINERS_POSTGRES" ]; then
    echo "Erro: Nenhum container Postgres encontrado."
    exit 1
fi

echo "Iniciando backup em massa de todos os containers Postgres..."

# Loop para processar cada container encontrado
for CONTAINER_DB_ALVO in $CONTAINERS_POSTGRES; do
    echo "-------------------------------------------"
    echo "PROCESSANDO: $CONTAINER_DB_ALVO"

    # 2. Identificação Automática do Projeto Compose via Label
    PROJECT_NAME=$(docker inspect "$CONTAINER_DB_ALVO" \
        --format='{{index .Config.Labels "com.docker.compose.project"}}' | tr -d '\r')

    # Se não houver projeto associado, pula para o próximo container
    if [ -z "$PROJECT_NAME" ]; then
        echo "Aviso: Container '$CONTAINER_DB_ALVO' não possui label de projeto. Pulando..."
        continue
    fi

    # 3. Nome do Volume baseado no Projeto
    VOLUME_BACKUP_COMPETE="${PROJECT_NAME}_backups"

    # Formato de pasta para organização: YYYY/MM
    DATA_PASTA=$(date +%Y/%m)

    # 4. Extração do Usuário Administrador (removendo \r oculto)
    DB_USER=$(docker inspect "$CONTAINER_DB_ALVO" \
        --format='{{range .Config.Env}}{{println .}}{{end}}' \
        | grep "^POSTGRES_USER=" \
        | cut -d'=' -f2 | tr -d '\r')

    DB_USER=${DB_USER:-postgres}

    # 5. Listagem de Bancos de Dados (usando docker exec local, sem pedir senha)
    BANCOS=$(docker exec -i "$CONTAINER_DB_ALVO" \
        psql -U "$DB_USER" -d postgres -t -A -c \
        "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

    echo "Projeto: $PROJECT_NAME | Volume: $VOLUME_BACKUP_COMPETE"

    if [ -z "$BANCOS" ]; then
        echo " -> Nenhum banco personalizado encontrado."
        continue
    fi

    for DB in $BANCOS; do
        # Limpa espaços em branco
        DB=$(echo "$DB" | xargs | tr -d '\r')

        [ -z "$DB" ] && continue

        echo " -> Fazendo dump do banco: $DB"

        # Garante que a pasta de destino do backup exista dentro do volume local
        # O caminho padrão de dados dos volumes Docker no Linux é /var/lib/docker/volumes/.../_data
        PASTA_DESTINO="/var/lib/docker/volumes/${VOLUME_BACKUP_COMPETE}/_data/${DB}/${DATA_PASTA}"
        mkdir -p "$PASTA_DESTINO"

        # 6. Executa o pg_dump LOCALMENTE dentro do container e extrai o arquivo gerado
        docker exec -i "$CONTAINER_DB_ALVO" pg_dump \
            -U "$DB_USER" \
            -d "$DB" \
            -F c \
            -Z 9 \
            -b > "$PASTA_DESTINO/db-$(date +%Y-%m-%d)-$(date +%H%M).backup"

        if [ ${PIPESTATUS[0]} -eq 0 ]; then
            echo "    Backup concluído com sucesso: $DB"
        else
            echo "    Erro ao fazer backup: $DB"
        fi
    done

    # 7. Limpeza de backups antigos e diretórios vazios usando o volume mapeado
    echo " -> Executando limpeza de backups antigos (+180 dias) e pastas vazias..."
    
    TARGET_VOL_DIR="/var/lib/docker/volumes/${VOLUME_BACKUP_COMPETE}/_data"
    if [ -d "$TARGET_VOL_DIR" ]; then
        find "$TARGET_VOL_DIR" -type f -mtime +180 -name '*.backup' -exec rm -f {} + 2>/dev/null
        find "$TARGET_VOL_DIR" -type d -empty -not -path "$TARGET_VOL_DIR" -exec rmdir -p {} + 2>/dev/null
    fi

done

echo "-------------------------------------------"
echo "Todos os processos finalizados: $(date '+%Y-%m-%d %H:%M:%S')"
echo "-------------------------------------------"

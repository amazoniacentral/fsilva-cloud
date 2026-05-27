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
        --format='{{index .Config.Labels "com.docker.compose.project"}}')

    # Se não houver projeto associado, pula para o próximo container
    if [ -z "$PROJECT_NAME" ]; then
        echo "Aviso: Container '$CONTAINER_DB_ALVO' não possui label de projeto. Pulando..."
        continue
    fi

    # 3. Identificação Automática da Rede
    NETWORK_NAME=$(docker inspect "$CONTAINER_DB_ALVO" \
        --format='{{range $net, $conf := .NetworkSettings.Networks}}{{println $net}}{{end}}' \
        | head -n 1)

    # 4. Nome do Volume baseado no Projeto
    VOLUME_BACKUP_COMPETE="${PROJECT_NAME}_backups"

    # Formato de pasta para organização: YYYY/MM
    DATA_PASTA=$(date +%Y/%m)

    # 5. Extração de Credenciais do Ambiente do Container
    DB_USER=$(docker inspect "$CONTAINER_DB_ALVO" \
        --format='{{range .Config.Env}}{{println .}}{{end}}' \
        | grep "^POSTGRES_USER=" \
        | cut -d'=' -f2)

    DB_USER=${DB_USER:-postgres}

    DB_PASS=$(docker inspect "$CONTAINER_DB_ALVO" \
        --format='{{range .Config.Env}}{{println .}}{{end}}' \
        | grep "^POSTGRES_PASSWORD=" \
        | cut -d'=' -f2)

    # 6. Listagem de Bancos de Dados
    BANCOS=$(docker exec "$CONTAINER_DB_ALVO" \
        env PGPASSWORD="$DB_PASS" \
        psql -U "$DB_USER" -d postgres -t -A -c \
        "SELECT datname
         FROM pg_database
         WHERE datistemplate = false
         AND datname != 'postgres';")

    echo "Projeto: $PROJECT_NAME | Rede: $NETWORK_NAME | Volume: $VOLUME_BACKUP_COMPETE"

    if [ -z "$BANCOS" ]; then
        echo " -> Nenhum banco encontrado."
        continue
    fi

    for DB in $BANCOS; do
        # Limpa espaços em branco
        DB=$(echo "$DB" | xargs)

        [ -z "$DB" ] && continue

        echo " -> Fazendo dump do banco: $DB"

        # Executa o dump usando container efêmero
        docker run --rm \
            --network "$NETWORK_NAME" \
            -v "$VOLUME_BACKUP_COMPETE":/backup \
            -e PGPASSWORD="$DB_PASS" \
            postgres:15-alpine \
            sh -c "
                mkdir -p /backup/${DB}/$DATA_PASTA && \
                pg_dump \
                    -h $CONTAINER_DB_ALVO \
                    -U $DB_USER \
                    -d $DB \
                | gzip > /backup/${DB}/$DATA_PASTA/${DB}_$(date +%Y-%m-%d)_$(date +%H%M).sql.gz
            "

        if [ $? -eq 0 ]; then
            echo "    Backup concluído: $DB"
        else
            echo "    Erro ao fazer backup: $DB"
        fi
    done

    # 7. Limpeza de backups antigos e diretórios vazios
    echo " -> Executando limpeza de backups antigos (+7 dias) e pastas vazias..."

    docker run --rm \
        -v "$VOLUME_BACKUP_COMPETE":/backup \
        alpine sh -c "
            find /backup -type f -mtime +7 -name '*.sql.gz' -exec rm -f {} + &&
            find /backup -type d -empty -not -path '/backup' -exec rmdir -p {} + 2>/dev/null
        "

done

echo "-------------------------------------------"
echo "Todos os processos finalizados: $(date '+%Y-%m-%d %H:%M:%S')"
echo "-------------------------------------------"
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
    PROJECT_NAME=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{index .Config.Labels "com.docker.compose.project"}}')

    # Se não houver projeto associado, pula para o próximo container
    if [ -z "$PROJECT_NAME" ]; then
        echo "Aviso: Container '$CONTAINER_DB_ALVO' não possui label de projeto. Pulando..."
        continue
    fi

    # 3. Identificação Automática da Rede (Pega a primeira conectada)
    NETWORK_NAME=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' | head -n 1)

    # 4. Nome do Volume baseado no Projeto (Padrão: nomeprojeto_backups)
    VOLUME_BACKUP_COMPETE="${PROJECT_NAME}_backups"
    
    DATA_PASTA=$(date +%Y-%m-%d)

    # 5. Extração de Credenciais do Ambiente do Container
    DB_USER=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep "^POSTGRES_USER=" | cut -d'=' -f2)
    DB_USER=${DB_USER:-postgres}
    DB_PASS=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep "^POSTGRES_PASSWORD=" | cut -d'=' -f2)

    # 6. Listagem de Bancos de Dados (Exclui templates e o banco padrão postgres)
    BANCOS=$(docker exec "$CONTAINER_DB_ALVO" psql -U "$DB_USER" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

    echo "Projeto: $PROJECT_NAME | Rede: $NETWORK_NAME | Volume: $VOLUME_BACKUP_COMPETE"

    for DB in $BANCOS; do
        # Limpa espaços em branco
        DB=$(echo $DB | xargs)
        [ -z "$DB" ] && continue

        echo " -> Fazendo dump do banco: $DB"
        
        # Executa o dump usando um container efêmero na mesma rede do alvo
        docker run --rm \
            --network "$NETWORK_NAME" \
            -v "$VOLUME_BACKUP_COMPETE":/backup \
            -e PGPASSWORD="$DB_PASS" \
            postgres:15-alpine \
            sh -c "mkdir -p /backup/database/$DATA_PASTA && pg_dump -h $CONTAINER_DB_ALVO -U $DB_USER $DB | gzip > /backup/database/$DATA_PASTA/${DB}_$(date +%H%M).sql.gz"
    done

    # 7. Limpeza: Remove backups com mais de 7 dias específicos deste projeto
    docker run --rm -v "$VOLUME_BACKUP_COMPETE":/backup alpine find /backup/database -type d -mtime +7 -exec rm -rf {} +

done

echo "-------------------------------------------"
echo "Todos os processos finalizados: $(date '+%Y-%m-%d %H:%M:%S')"
echo "-------------------------------------------"

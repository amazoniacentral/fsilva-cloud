#!/bin/bash

# 1. Identificação Automática do Container
# Busca o primeiro container que tenha "postgres" no nome e esteja rodando
CONTAINER_DB_ALVO=$(docker ps --filter "name=postgres" --filter "status=running" --format "{{.Names}}" | head -n 1)

if [ -z "$CONTAINER_DB_ALVO" ]; then
    echo "Erro: Nenhum container Postgres encontrado."
    exit 1
fi

# 2. Identificação Automática da Rede
# Pega a primeira rede conectada ao container
NETWORK_NAME=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' | head -n 1)

# 3. Identificação Automática do Volume
# Busca o nome do primeiro volume do tipo 'volume' (não bind mount) associado ao container
VOLUME_DESTINO=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{end}}{{end}}' | head -n 1)

# Fallback: Caso não encontre volume via inspect, define um padrão ou encerra
VOLUME_DESTINO=${VOLUME_DESTINO:-"backups_db_default"}

DATA_PASTA=$(date +%Y-%m-%d)

# 4. Pega as credenciais de dentro do container vivo
DB_USER=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep "^POSTGRES_USER=" | cut -d'=' -f2)
DB_USER=${DB_USER:-postgres}
DB_PASS=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep "^POSTGRES_PASSWORD=" | cut -d'=' -f2)

# 5. Descobre quais bancos existem
BANCOS=$(docker exec "$CONTAINER_DB_ALVO" psql -U "$DB_USER" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

echo "-------------------------------------------"
echo "BACKUP DINÂMICO DE BANCO DE DADOS"
echo "-------------------------------------------"
echo "Container Alvo: $CONTAINER_DB_ALVO"
echo "Rede Detectada: $NETWORK_NAME"
echo "Volume Destino: $VOLUME_DESTINO"
echo "-------------------------------------------"

for DB in $BANCOS; do
    # Remove espaços em branco do nome do banco
    DB=$(echo $DB | xargs)
    [ -z "$DB" ] && continue

    echo "Fazendo dump do banco: $DB"
    
    # Roda o container efêmero na mesma rede do container alvo
    docker run --rm \
        --network "$NETWORK_NAME" \
        -v "$VOLUME_DESTINO":/backup \
        -e PGPASSWORD="$DB_PASS" \
        postgres:15-alpine \
        sh -c "mkdir -p /backup/database/$DATA_PASTA && pg_dump -h $CONTAINER_DB_ALVO -U $DB_USER $DB | gzip > /backup/database/$DATA_PASTA/${DB}_$(date +%H%M).sql.gz"
done

# 6. Limpeza de backups antigos (mais de 7 dias)
docker run --rm -v "$VOLUME_DESTINO":/backup alpine find /backup/database -type d -mtime +7 -exec rm -rf {} +

echo "-------------------------------------------"
echo "Finalizado: $(date '+%Y-%m-%d %H:%M:%S')"
echo "-------------------------------------------"

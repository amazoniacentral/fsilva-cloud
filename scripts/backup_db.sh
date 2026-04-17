#!/bin/bash

# 1. Configurações
CONTAINER_DB_ALVO="postgres"   # Nome do container do Postgres
VOLUME_DESTINO="backups"      # Nome do volume onde você quer salvar
NETWORK_NAME="net_db"   # Nome da rede do seu docker-compose
DATA_PASTA=$(date +%Y-%m-%d)

# 2. Pega as credenciais e rede de dentro do container vivo
DB_USER=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep "^POSTGRES_USER=" | cut -d'=' -f2)
DB_USER=${DB_USER:-postgres}
DB_PASS=$(docker inspect "$CONTAINER_DB_ALVO" --format='{{range .Config.Env}}{{println .}}{{end}}' | grep "^POSTGRES_PASSWORD=" | cut -d'=' -f2)

# 3. Descobre quais bancos existem
BANCOS=$(docker exec "$CONTAINER_DB_ALVO" psql -U "$DB_USER" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname != 'postgres';")

echo "-------------------------------------------"
echo "BACKUP BANCO DE DADOS"
echo "-------------------------------------------"
echo "Iniciando backups individuais para o volume: $VOLUME_DESTINO"

for DB in $BANCOS; do
    echo "Fazendo dump do banco: $DB"
    
    # Roda o container efêmero
    # Mapeamos o volume 'databases' para a pasta /backup dentro do container
    docker run --rm \
        --network "$NETWORK_NAME" \
        -v "$VOLUME_DESTINO":/backup \
        -e PGPASSWORD="$DB_PASS" \
        postgres:15-alpine \
        sh -c "mkdir -p /backup/backups_db/$DATA_PASTA && pg_dump -h $CONTAINER_DB_ALVO -U $DB_USER $DB | gzip > /backup/backups_db/$DATA_PASTA/${DB}_$(date +%H%M).sql.gz"
done

# 4. Limpeza de backups antigos dentro do volume (mais de 7 dias)
docker run --rm -v "$VOLUME_DESTINO":/backup alpine find /backup/backups_db -type d -mtime +7 -exec rm -rf {} +

echo "-------------------------------------------"
echo "Finalizado: $(date '+%Y-%m-%d %H:%M:%S')"
echo "Arquivos seguros no volume: $VOLUME_DESTINO"
echo "-------------------------------------------"
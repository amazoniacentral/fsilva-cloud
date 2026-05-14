#!/bin/bash

# Pega o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Caminho do seu diretório de deploy (ajustado para subir um nível conforme seu script original)
CD_DIR="$SCRIPT_DIR/.."
ACME_FILE="$CD_DIR/proxy/traefik/certificados/acme.json"

echo "Iniciando limpeza de certificados órfãos..."

# 1. Backup de segurança
BACKUP_DIR="$CD_DIR/proxy/traefik/certificados/backups"

mkdir -p $BACKUP_DIR

# 1. Faz o backup ANTES de qualquer alteração
if [ -f "$ACME_FILE" ]; then
    cp $ACME_FILE "$BACKUP_DIR/acme_$(date +%Y%m%d_%H%M%S).json.bak"
fi

# 2. Limpeza Inteligente: Mantém 15 dias.
find $BACKUP_DIR -name "*.bak" -type f -mtime +15 -delete

# Entra no diretório onde o docker-compose.yml está para evitar erro de "not found"
cd "$CD_DIR"

# Verifica se o container está rodando
IS_RUNNING=$(docker compose ps -q traefik | xargs docker inspect -f '{{.State.Running}}' 2>/dev/null)

# 2. Para o Traefik apenas se estiver rodando
if [ "$IS_RUNNING" == "true" ]; then
    docker compose stop traefik
fi

# 3. Remove o arquivo antigo e cria um novo zerado
rm -f $ACME_FILE
touch $ACME_FILE
chmod 600 $ACME_FILE

# 4. Inicia o Traefik apenas se ele estava rodando anteriormente
if [ "$IS_RUNNING" == "true" ]; then
    docker compose start traefik
fi
cd "$SCRIPT_DIR"

echo "Limpeza concluída. O Traefik está gerando novos certificados apenas para lojas ativas."

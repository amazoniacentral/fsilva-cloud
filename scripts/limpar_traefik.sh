#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
# Caminho do seu diretório de deploy
CD_DIR="$SCRIPT_DIR/.."
ACME_FILE="$CD_DIR/proxy/traefik/certificados/acme.json"

echo "Iniciando limpeza de certificados órfãos..."

# 1. Backup de segurança
BACKUP_DIR="$CD_DIR/proxy/traefik/certificados/backups"

mkdir -p $BACKUP_DIR

# 1. Faz o backup ANTES de qualquer alteração
# Usamos o timestamp para garantir que o arquivo seja único
cp $ACME_FILE "$BACKUP_DIR/acme_$(date +%Y%m%d_%H%M%S).json.bak"

# 2. Limpeza Inteligente: Mantém 15 dias.
# Como você roda a cada 7 dias, você sempre terá os últimos 2 backups guardados.
find $BACKUP_DIR -name "*.bak" -type f -mtime +15 -delete
# 2. Para o Traefik (essencial para não corromper o JSON)
docker compose -f $CD_DIR/docker-compose.yml stop traefik

# 3. Remove o arquivo antigo e cria um novo zerado
# O Traefik vai re-gerar apenas o que estiver com container ATIVO agora
rm $ACME_FILE
touch $ACME_FILE
chmod 600 $ACME_FILE

# 4. Inicia o Traefik
docker compose -f $CD_DIR/docker-compose.yml start traefik

echo "Limpeza concluída. O Traefik está gerando novos certificados apenas para lojas ativas."

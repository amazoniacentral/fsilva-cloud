#!/bin/bash
set -euo pipefail

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

BACKUP_DIR="/var/lib/docker/volumes/backups/_data"
CONTAINER_DJANGO="sgn-django"
CONTAINER_PG="sgn-postgres"
DOT_ENV_PATH="./.env"

# 0. CARGA DO ARQUIVO .ENV
if [ -f "$DOT_ENV_PATH" ]; then
    echo -e "📖 Carregando configurações de: ${CYAN}$DOT_ENV_PATH${RESET}"
    export $(grep -v '^#' "$DOT_ENV_PATH" | xargs)
fi

echo -e "${CYAN}📁 Gestão de Backup do Banco de Dados${RESET}"
echo "------------------------------------------------"
echo "1) Baixar novo backup via Rsync"
echo "2) Selecionar backup existente no volume"
read -rp "Escolha uma opção (1 ou 2): " OPCAO_INICIAL

if [[ "$OPCAO_INICIAL" == "1" ]]; then
    # Solicita dados de origem apenas se não estiverem no .env
    [[ -z "${RSYNC_ORIGEM_USER:-}" ]] && read -rp "Usuário remoto: " RSYNC_ORIGEM_USER
    [[ -z "${RSYNC_ORIGEM_IP:-}" ]] && read -rp "IP remoto: " RSYNC_ORIGEM_IP
    [[ -z "${RSYNC_ORIGEM_PATH:-}" ]] && read -rp "Caminho do arquivo remoto: " RSYNC_ORIGEM_PATH

    ARQUIVO_PARA_RESTAURAR=$(mktemp ${BACKUP_DIR}/banco_XXXXXX.backup)
    
    echo -e "\n🔄 Iniciando download para: $ARQUIVO_PARA_RESTAURAR"
    sudo rsync -avz --progress "${RSYNC_ORIGEM_USER}@${RSYNC_ORIGEM_IP}:${RSYNC_ORIGEM_PATH}" "$ARQUIVO_PARA_RESTAURAR"
    echo -e "✅ Download concluído."

else
    echo -e "\n📂 Arquivos disponíveis em $BACKUP_DIR:"
    mapfile -t BACKUPS < <(ls -1 "$BACKUP_DIR"/*.backup 2>/dev/null || ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null)
    
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum arquivo encontrado no volume de backup.${RESET}"
        exit 1
    fi

    for i in "${!BACKUPS[@]}"; do
        echo "$((i+1))) $(basename "${BACKUPS[$i]}")"
    done

    read -rp "Selecione o número do backup: " SELECAO
    ARQUIVO_PARA_RESTAURAR="${BACKUPS[$((SELECAO-1))]}"
fi

echo -e "\n🔍 Extraindo credenciais do container $CONTAINER_DJANGO..."
# Extrai DATABASE_URL e faz o parse
DB_URL=$(docker exec "$CONTAINER_DJANGO" env | grep DATABASE_URL | cut -d'=' -f2)

# Parse robusto para extração de credenciais
PG_USER=$(echo "$DB_URL" | sed -e 's|.*//\(.*\):.*@.*|\1|')
PG_PASSWORD=$(echo "$DB_URL" | sed -e 's|.*: \(.*\)@.*|\1|' | cut -d':' -f2 | cut -d'@' -f1)
PG_NAME=$(echo "$DB_URL" | awk -F'/' '{print $NF}' | cut -d'?' -f1)

echo -e "🚀 Parando container Django para evitar conexões presas..."
docker stop "$CONTAINER_DJANGO"

# 7. LIMPEZA RADICAL (DROP SCHEMA)
echo -e "🧹 Realizando limpeza atômica do schema public..."
LIMPAR_CMD="DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO public; GRANT ALL ON SCHEMA public TO $PG_USER;"
if ! docker exec -i -e PGPASSWORD="$PG_PASSWORD" "$CONTAINER_PG" psql -U "$PG_USER" -d "$PG_NAME" -c "$LIMPAR_CMD"; then
    echo -e "❌ Erro ao zerar banco. Certifique-se de que não há outras conexões."
    docker start "$CONTAINER_DJANGO"
    exit 1
fi

# 8. RESTAURAÇÃO POR FORMATO
echo -e "⏳ Restaurando dados de: $(basename "$ARQUIVO_PARA_RESTAURAR")"
if head -c 5 "$ARQUIVO_PARA_RESTAURAR" | grep -q "PGDMP"; then
    echo -e "📦 Formato BINÁRIO (pg_restore)..."
    docker exec -i -e PGPASSWORD="$PG_PASSWORD" "$CONTAINER_PG" pg_restore -U "$PG_USER" -d "$PG_NAME" --no-owner < "$ARQUIVO_PARA_RESTAURAR" || echo "⚠️ Avisos no restore."
else
    echo -e "📄 Formato SQL TEXTO (psql)..."
    docker exec -i -e PGPASSWORD="$PG_PASSWORD" "$CONTAINER_PG" psql -U "$PG_USER" -d "$PG_NAME" < "$ARQUIVO_PARA_RESTAURAR"
fi

# 9. REINICIAR DJANGO E RODAR MIGRATE
echo -e "\n🚀 Iniciando container '$CONTAINER_DJANGO' e rodando migrações..."
docker start "$CONTAINER_DJANGO"
sleep 3
docker exec -i "$CONTAINER_DJANGO" python manage.py migrate

echo -e "\n${CYAN}================================================================${RESET}"
echo -e "✅  BANCO RESTAURADO E SISTEMA ONLINE!"
echo -e "${CYAN}================================================================${RESET}"

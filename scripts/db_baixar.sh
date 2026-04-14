#!/bin/bash
set -euo pipefail

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# CONFIGURAÇÕES DE NOMES (AJUSTE SE NECESSÁRIO)
BACKUP_DIR="/var/lib/docker/volumes/backups/_data"
CONTAINER_DJANGO="sgn-django"
CONTAINER_PG="postgres"
CONTAINER_CELERY="sgn-celery-worker"
CONTAINER_BEAT="sgn-celery-beat"
CONTAINER_REDIS="db-redis"
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
    REMOTE_PATH="${RSYNC_ORIGEM_PATH_2:-${DESTINO_PATH_BANCO:-}}"
    [[ -z "${RSYNC_ORIGEM_USER:-}" ]] && read -rp "Usuário remoto: " RSYNC_ORIGEM_USER
    [[ -z "${RSYNC_ORIGEM_IP:-}" ]] && read -rp "IP remoto: " RSYNC_ORIGEM_IP
    [[ -z "$REMOTE_PATH" ]] && read -rp "Caminho do arquivo remoto: " REMOTE_PATH

    ARQUIVO_PARA_RESTAURAR=$(mktemp ${BACKUP_DIR}/banco_XXXXXX.backup)
    
    echo -e "\n🔄 Iniciando download para: $ARQUIVO_PARA_RESTAURAR"
    rsync -avz --progress "${RSYNC_ORIGEM_USER}@${RSYNC_ORIGEM_IP}:${REMOTE_PATH}" "$ARQUIVO_PARA_RESTAURAR"
    echo -e "✅ Download concluído."
else
    echo -e "\n📂 Arquivos disponíveis em $BACKUP_DIR:"
    mapfile -t BACKUPS < <(ls -1 "$BACKUP_DIR"/*.backup 2>/dev/null || ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null)
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum arquivo encontrado.${RESET}"
        exit 1
    fi
    for i in "${!BACKUPS[@]}"; do echo "$((i+1))) $(basename "${BACKUPS[$i]}")"; done
    read -rp "Selecione o número: " SELECAO
    ARQUIVO_PARA_RESTAURAR="${BACKUPS[$((SELECAO-1))]}"
fi

echo -e "\n🔍 Extraindo credenciais do container $CONTAINER_DJANGO..."
DB_URL=$(docker exec "$CONTAINER_DJANGO" env | grep DATABASE_URL | cut -d'=' -f2)
PG_USER=$(echo "$DB_URL" | sed -e 's|.*//\(.*\):.*@.*|\1|')
PG_PASSWORD=$(echo "$DB_URL" | sed -e 's|.*: \(.*\)@.*|\1|' | cut -d':' -f2 | cut -d'@' -f1)
PG_NAME=$(echo "$DB_URL" | awk -F'/' '{print $NF}' | cut -d'?' -f1)

echo -e "🚀 Parando serviços para liberar conexões..."
docker stop "$CONTAINER_DJANGO" "$CONTAINER_CELERY" "$CONTAINER_BEAT" || true

# 7. LIMPEZA RADICAL
echo -e "🧹 Realizando limpeza atômica do schema public no container '$CONTAINER_PG'..."
LIMPAR_CMD="DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO public; GRANT ALL ON SCHEMA public TO $PG_USER;"
if ! docker exec -i -e PGPASSWORD="$PG_PASSWORD" "$CONTAINER_PG" psql -U "$PG_USER" -d "$PG_NAME" -c "$LIMPAR_CMD"; then
    echo -e "${RED}❌ Erro ao zerar banco. Verifique se o container '$CONTAINER_PG' existe.${RESET}"
    docker start "$CONTAINER_DJANGO" "$CONTAINER_CELERY" "$CONTAINER_BEAT"
    exit 1
fi

# 8. RESTAURAÇÃO
echo -e "⏳ Restaurando dados..."
if head -c 5 "$ARQUIVO_PARA_RESTAURAR" | grep -q "PGDMP"; then
    docker exec -i -e PGPASSWORD="$PG_PASSWORD" "$CONTAINER_PG" pg_restore -U "$PG_USER" -d "$PG_NAME" --no-owner < "$ARQUIVO_PARA_RESTAURAR" || echo "⚠️ Avisos no restore."
else
    docker exec -i -e PGPASSWORD="$PG_PASSWORD" "$CONTAINER_PG" psql -U "$PG_USER" -d "$PG_NAME" < "$ARQUIVO_PARA_RESTAURAR"
fi

# 9. REINICIAR TUDO
echo -e "\n🚀 Reiniciando serviços e rodando migrações..."
docker start "$CONTAINER_DJANGO" "$CONTAINER_CELERY" "$CONTAINER_BEAT"
sleep 3
docker exec -i "$CONTAINER_DJANGO" python manage.py migrate

echo -e "\n${CYAN}================================================================${RESET}"
echo -e "✅  SISTEMA RESTAURADO E ONLINE!"
echo -e "${CYAN}================================================================${RESET}"

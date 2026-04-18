#!/bin/bash
set -euo pipefail

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# CONFIGURAÇÕES DE NOMES
BACKUP_DIR="/var/lib/docker/volumes/backups/_data"
CONTAINER_DJANGO="sgn-django"
CONTAINER_PG="postgres"
CONTAINER_CELERY="sgn-celery-worker"
CONTAINER_BEAT="sgn-celery-beat"
DOT_ENV_PATH="./.env"

clear
echo -e "${CYAN}================================================================${RESET}"
echo -e "${YELLOW}           RESTAURAÇÃO BANCO DE DADOS - SGN CLOUD${RESET}"
echo -e "${CYAN}================================================================${RESET}"

# 0. CARGA DO ARQUIVO .ENV LOCAL
if [ -f "$DOT_ENV_PATH" ]; then
    echo -e "📖 Carregando configurações de: ${CYAN}$DOT_ENV_PATH${RESET}"
    export $(grep -v '^#' "$DOT_ENV_PATH" | xargs)
fi

echo -e "${CYAN}📁 Gestão de Backup${RESET}"
echo -e "\n------------------------------------------------"
echo "1) Baixar novo backup via Rsync"
echo "2) Selecionar backup existente no volume"
read -rp "Escolha uma opção (1 ou 2): " OPCAO_INICIAL

if [[ "$OPCAO_INICIAL" == "1" ]]; then
    REMOTE_PATH="${RSYNC_ORIGEM_PATH:-${DESTINO_PATH_BANCO:-}}"
    [[ -z "${RSYNC_ORIGEM_USER:-}" ]] && read -rp "👉 Usuário remoto (SSH): " RSYNC_ORIGEM_USER
    [[ -z "${RSYNC_ORIGEM_IP:-}" ]] && read -rp "👉 IP remoto: " RSYNC_ORIGEM_IP
    [[ -z "$REMOTE_PATH" ]] && read -rp "👉 Caminho do arquivo remoto: " REMOTE_PATH

    ARQUIVO_PARA_RESTAURAR=$(mktemp ${BACKUP_DIR}/banco_XXXXXX.backup)
    
    echo -e "\n🔄 Iniciando download..."
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
    read -rp "Selecione o número do backup: " SELECAO
    ARQUIVO_PARA_RESTAURAR="${BACKUPS[$((SELECAO-1))]}"
fi

echo -e "\n------------------------------------------------"
echo -e "🔍 Extraindo credenciais..."

# 1. Dados do Django/App (extraídos do container)
DB_URL=$(docker exec "$CONTAINER_DJANGO" env | grep DATABASE_URL | cut -d'=' -f2 || echo "")
PG_USER_APP=$(echo "$DB_URL" | sed -e 's|.*//\(.*\):.*@.*|\1|')
PG_PASS_APP=$(echo "$DB_URL" | sed -e 's|.*://[^:]*:\(.*\)@.*|\1|')
PG_NAME=$(echo "$DB_URL" | awk -F'/' '{print $NF}' | cut -d'?' -f1)

# Caso a extração automática falhe
[[ -z "$PG_USER_APP" ]] && read -rp "👉 Usuário do Banco (App): " PG_USER_APP
[[ -z "$PG_NAME" ]] && read -rp "👉 Nome do Banco de Dados: " PG_NAME

# 2. Dados do Super-usuário do Postgres
PG_SUPER_USER=$(docker exec "$CONTAINER_PG" env | grep POSTGRES_USER | cut -d'=' -f2 || echo "postgres")
PG_SUPER_PASS=$(docker exec "$CONTAINER_PG" env | grep POSTGRES_PASSWORD | cut -d'=' -f2 || echo "")

echo -e "\n------------------------------------------------"
echo -e "🚀 Parando serviços para liberar o banco..."
docker stop "$CONTAINER_DJANGO" "$CONTAINER_CELERY" "$CONTAINER_BEAT" || true

# 7. LIMPEZA RADICAL E DEFINIÇÃO DE OWNER
echo -e "\n------------------------------------------------"
echo -e "🧹 Resetando Schema Public no banco: ${YELLOW}$PG_NAME${RESET}"
# Limpa o schema e já define o usuário do APP como dono para evitar erros de permissão futuros
LIMPAR_CMD="DROP SCHEMA public CASCADE; CREATE SCHEMA public; ALTER SCHEMA public OWNER TO \"$PG_USER_APP\"; GRANT ALL ON SCHEMA public TO \"$PG_USER_APP\"; GRANT ALL ON SCHEMA public TO public;"

docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c "$LIMPAR_CMD"

# 8. RESTAURAÇÃO DE DADOS
echo -e "\n------------------------------------------------"
echo -e "⏳ Restaurando: $(basename "$ARQUIVO_PARA_RESTAURAR")"

if head -c 5 "$ARQUIVO_PARA_RESTAURAR" | grep -q "PGDMP"; then
    echo -e "📦 Formato BINÁRIO. Usando ${YELLOW}pg_restore${RESET} com role: ${CYAN}$PG_USER_APP${RESET}"
    # Restaura usando o SuperUser mas atribuindo cada objeto ao usuário do APP
    cat "$ARQUIVO_PARA_RESTAURAR" | docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" pg_restore -U "$PG_SUPER_USER" -d "$PG_NAME" --no-owner --no-privileges --role="$PG_USER_APP" || echo "Avisos ignorados no restore."
else
    echo -e "📄 Formato SQL TEXTO. Usando ${YELLOW}psql${RESET}..."
    docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" < "$ARQUIVO_PARA_RESTAURAR"
fi

# Ajuste de Permissões Finais (Caso o dump tenha trazido owners estranhos)
echo -e "🔑 Garantindo permissões finais para o usuário: $PG_USER_APP"
AJUSTE_CMD="GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO \"$PG_USER_APP\"; GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO \"$PG_USER_APP\";"
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c "$AJUSTE_CMD"

# 9. REINICIALIZAÇÃO E MIGRATE
echo -e "\n------------------------------------------------"
echo -e "🚀 Reiniciando serviços..."
docker start "$CONTAINER_DJANGO" "$CONTAINER_CELERY" "$CONTAINER_BEAT"
sleep 5

echo -e "\n========================================================"
echo "Deseja sincronizar migrações agora?"
echo "1) Sim (Executar migrate --fake)"
echo "2) Não (Sair)"
read -rp "Opção: " SYNC_OPCAO

if [ "$SYNC_OPCAO" == "1" ]; then
    echo "--------------------------------------------------------"
    echo "== Sincronizando Migrations =="
    # Verifica se o banco está legível pelo Django e aplica o fake
    if docker exec -i "$CONTAINER_DJANGO" python manage.py showmigrations > /dev/null 2>&1; then
        docker exec -i "$CONTAINER_DJANGO" python manage.py migrate --fake
        echo -e "${GREEN}✅ Sincronização concluída com sucesso!${RESET}"
    else
        echo -e "${RED}❌ O Django ainda não tem permissão. Verifique as credenciais no .env.${RESET}"
    fi
fi

echo -e "\n${CYAN}================================================================${RESET}"
echo -e "${GREEN}🏁  PROCESSO FINALIZADO!${RESET}"
echo -e "${CYAN}================================================================${RESET}"

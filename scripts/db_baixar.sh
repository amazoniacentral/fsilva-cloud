#!/bin/bash
set -euo pipefail

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Função para selecionar container por padrão de nome e prefixo de projeto
selecionar_container() {
    local pattern=$1
    local prefixo=$2
    local prompt=$3
    
    # Filtra containers que contenham o prefixo e batem com o padrão do serviço
    mapfile -t containers < <(docker ps --format "{{.Names}}" | grep "^${prefixo}" | grep -i "$pattern")
    
    if [ ${#containers[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum container encontrado para $prompt com prefixo $prefixo e padrão $pattern${RESET}"
        exit 1
    elif [ ${#containers[@]} -eq 1 ]; then
        echo "${containers[0]}"
    else
        echo -e "\n${YELLOW}Selecione o container $prompt:${RESET}" >&2
        for i in "${!containers[@]}"; do echo "$((i+1))) ${containers[$i]}" >&2; done
        read -rp "Opção: " idx < /dev/tty
        echo "${containers[$((idx-1))]}"
    fi
}

clear
echo -e "${CYAN}================================================================${RESET}"
echo -e "${YELLOW}           RESTAURAÇÃO DINÂMICA - SGN CLOUD${RESET}"
echo -e "${CYAN}================================================================${RESET}"

# 1. IDENTIFICAÇÃO DOS PROJETOS DISPONÍVEIS
# Lista todos os containers e tenta extrair o prefixo (tudo antes do sufixo do serviço comum)
# Aqui usamos o Django como referência de nome de projeto
mapfile -t PROJETOS < <(docker ps --format "{{.Names}}" | grep "django" | sed 's/-django.*//' | sort -u)

if [ ${#PROJETOS[@]} -eq 0 ]; then
    # Fallback caso não encontre pelo padrão django: lista o primeiro termo antes do hífen
    mapfile -t PROJETOS < <(docker ps --format "{{.Names}}" | cut -d'-' -f1 | sort -u)
fi

if [ ${#PROJETOS[@]} -eq 0 ]; then
    echo -e "${RED}❌ Nenhum projeto Docker identificado.${RESET}"
    exit 1
fi

echo -e "${YELLOW}Selecione o Projeto:${RESET}"
for i in "${!PROJETOS[@]}"; do
    echo "$((i+1))) ${PROJETOS[$i]}"
done
read -rp "Projeto: " p_idx
PROJETO_PREFIX="${PROJETOS[$((p_idx-1))]}"

# 2. SELEÇÃO DINÂMICA DE CONTAINERS DO PROJETO
CONTAINER_DJANGO=$(selecionar_container "django" "$PROJETO_PREFIX" "Django/App")
CONTAINER_PG=$(selecionar_container "postgres" "$PROJETO_PREFIX" "PostgreSQL")
CONTAINER_CELERY=$(selecionar_container "worker" "$PROJETO_PREFIX" "Celery Worker")
CONTAINER_BEAT=$(selecionar_container "beat" "$PROJETO_PREFIX" "Celery Beat")

# 3. SELEÇÃO DINÂMICA DE VOLUME (Busca volume de backup no projeto selecionado)
echo -e "\n${YELLOW}Buscando volumes de Backup associados ao projeto...${RESET}"
# Lista volumes que pertencem ao container Django selecionado
mapfile -t VOLUMES < <(docker inspect "$CONTAINER_DJANGO" --format='{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' | grep -v '^$')

if [ ${#VOLUMES[@]} -eq 0 ]; then
    echo -e "${RED}❌ Nenhum volume do tipo 'volume' encontrado no container $CONTAINER_DJANGO.${RESET}"
    exit 1
fi

# Filtra automaticamente se houver algum com "backup" no nome, senão lista todos
mapfile -t VOLUMES_BACKUP < <(printf '%s\n' "${VOLUMES[@]}" | grep -i "backup" || printf '%s\n' "${VOLUMES[@]}")

if [ ${#VOLUMES_BACKUP[@]} -eq 1 ]; then
    VOLUME_NAME="${VOLUMES_BACKUP[0]}"
    echo -e "✅ Volume selecionado: ${GREEN}$VOLUME_NAME${RESET}"
else
    echo -e "\n${YELLOW}Selecione o volume de backup:${RESET}"
    for i in "${!VOLUMES_BACKUP[@]}"; do 
        echo "$((i+1))) ${VOLUMES_BACKUP[$i]}"
    done
    read -rp "Escolha o número: " v_idx
    VOLUME_NAME="${VOLUMES_BACKUP[$((v_idx-1))]}"
fi

BACKUP_DIR="/var/lib/docker/volumes/${VOLUME_NAME}/_data"
DOT_ENV_PATH="./.env"

# --- FLUXO DE RESTAURAÇÃO ---

if [ -f "$DOT_ENV_PATH" ]; then
    echo -e "📖 Carregando configurações de: ${CYAN}$DOT_ENV_PATH${RESET}"
    export $(grep -v '^#' "$DOT_ENV_PATH" | xargs)
fi

echo -e "\n------------------------------------------------"
echo "1) Baixar novo backup via Rsync"
echo "2) Selecionar backup existente no volume: $VOLUME_NAME"
read -rp "Escolha uma opção (1 ou 2): " OPCAO_INICIAL

if [[ "$OPCAO_INICIAL" == "1" ]]; then
    REMOTE_PATH="${RSYNC_ORIGEM_PATH:-${DESTINO_PATH_BANCO:-}}"
    [[ -z "${RSYNC_ORIGEM_USER:-}" ]] && read -rp "👉 Usuário remoto (SSH): " RSYNC_ORIGEM_USER
    [[ -z "${RSYNC_ORIGEM_IP:-}" ]] && read -rp "👉 IP remoto: " RSYNC_ORIGEM_IP
    [[ -z "$REMOTE_PATH" ]] && read -rp "👉 Caminho do arquivo remoto: " REMOTE_PATH

    ARQUIVO_PARA_RESTAURAR=$(mktemp ${BACKUP_DIR}/banco_XXXXXX.backup)
    
    echo -e "\n🔄 Iniciando download..."
    rsync -avz --progress "${RSYNC_ORIGEM_USER}@${RSYNC_ORIGEM_IP}:${REMOTE_PATH}" "$ARQUIVO_PARA_RESTAURAR"
else
    echo -e "\n📂 Arquivos disponíveis em $BACKUP_DIR:"
    mapfile -t BACKUPS < <(ls -1 "$BACKUP_DIR"/*.backup 2>/dev/null || ls -1 "$BACKUP_DIR"/*.sql 2>/dev/null)
    if [ ${#BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}❌ Nenhum arquivo encontrado em $BACKUP_DIR${RESET}"
        exit 1
    fi
    for i in "${!BACKUPS[@]}"; do echo "$((i+1))) $(basename "${BACKUPS[$i]}")"; done
    read -rp "Selecione o número do backup: " SELECAO
    ARQUIVO_PARA_RESTAURAR="${BACKUPS[$((SELECAO-1))]}"
fi

echo -e "\n🔍 Extraindo credenciais de $CONTAINER_DJANGO..."
DB_URL=$(docker exec "$CONTAINER_DJANGO" env | grep DATABASE_URL | cut -d'=' -f2 || echo "")
PG_USER_APP=$(echo "$DB_URL" | sed -e 's|.*//\(.*\):.*@.*|\1|')
PG_NAME=$(echo "$DB_URL" | awk -F'/' '{print $NF}' | cut -d'?' -f1)

PG_SUPER_USER=$(docker exec "$CONTAINER_PG" env | grep POSTGRES_USER | cut -d'=' -f2 || echo "postgres")
PG_SUPER_PASS=$(docker exec "$CONTAINER_PG" env | grep POSTGRES_PASSWORD | cut -d'=' -f2 || echo "")

echo -e "\n🚀 Parando serviços para liberar o banco..."
docker stop "$CONTAINER_DJANGO" "$CONTAINER_CELERY" "$CONTAINER_BEAT" || true

echo -e "\n🧹 Resetando Schema Public no banco: ${YELLOW}$PG_NAME${RESET}"
LIMPAR_CMD="DROP SCHEMA public CASCADE; CREATE SCHEMA public; ALTER SCHEMA public OWNER TO \"$PG_USER_APP\"; GRANT ALL ON SCHEMA public TO \"$PG_USER_APP\"; GRANT ALL ON SCHEMA public TO public;"
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c "$LIMPAR_CMD"

echo -e "\n⏳ Restaurando: $(basename "$ARQUIVO_PARA_RESTAURAR")"
if head -c 5 "$ARQUIVO_PARA_RESTAURAR" | grep -q "PGDMP"; then
    cat "$ARQUIVO_PARA_RESTAURAR" | docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" pg_restore -U "$PG_SUPER_USER" -d "$PG_NAME" --no-owner --no-privileges --role="$PG_USER_APP"
else
    docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" < "$ARQUIVO_PARA_RESTAURAR"
fi

echo -e "🚀 Reiniciando serviços..."
docker start "$CONTAINER_DJANGO" "$CONTAINER_CELERY" "$CONTAINER_BEAT"

echo -e "\n${GREEN}🏁  PROCESSO FINALIZADO!${RESET}"

#!/bin/bash
# Script de Restauração de Banco - SGN CLOUD
set -uo pipefail

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# --- FUNÇÕES ---

selecionar_container() {
    local pattern=$1
    local prefixo=$2
    local prompt=$3
    local obrigatorio=${4:-true}

    mapfile -t containers < <(docker ps --format "{{.Names}}" | grep "^${prefixo}" | grep -i "$pattern" || true)

    if [ ${#containers[@]} -eq 0 ]; then
        if [ "$obrigatorio" = true ]; then
            echo -e "${RED}❌ Nenhum container encontrado para $prompt${RESET}"
            exit 1
        fi
        return
    elif [ ${#containers[@]} -eq 1 ]; then
        echo "${containers[0]}"
    else
        echo -e "\n${YELLOW}Selecione o container $prompt:${RESET}" >&2
        for i in "${!containers[@]}"; do echo "$((i+1))) ${containers[$i]}" >&2; done
        read -rp "Opção: " idx < /dev/tty
        echo "${containers[$((idx-1))]}"
    fi
}

extrair_credenciais() {
    local container_app=$1
    echo -e "${CYAN}🔍 Extraindo credenciais de: $container_app${RESET}"
    
    local env_vars=$(docker exec "$container_app" env 2>/dev/null || echo "")

    if [[ "$container_app" == *"django"* ]]; then
        local url=$(echo "$env_vars" | grep "^DATABASE_URL=" | cut -d'=' -f2-)
        PG_USER_APP=$(echo "$url" | sed -E 's#postgres(ql)?://([^:]+):.*#\2#')
        PG_PASS_APP=$(echo "$url" | sed -E 's#postgres(ql)?://[^:]+:([^@]+)@.*#\2#')
        PG_NAME=$(echo "$url" | sed -E 's#.*/([^/?]+).*#\1#')
    
    elif [[ "$container_app" == *"n8n"* ]]; then
        PG_NAME=$(echo "$env_vars" | grep -i "DB_POSTGRESDB_DATABASE" | cut -d'=' -f2 | tr -d '\r')
        PG_USER_APP=$(echo "$env_vars" | grep -i "DB_POSTGRESDB_USER" | cut -d'=' -f2 | tr -d '\r')
        PG_PASS_APP=$(echo "$env_vars" | grep -i "DB_POSTGRESDB_PASSWORD" | cut -d'=' -f2 | tr -d '\r')
    
    else
        echo -e "${RED}❌ Tipo de container não mapeado para extração automática.${RESET}"
        exit 1
    fi

    if [ -z "${PG_NAME:-}" ]; then
        echo -e "${RED}❌ Falha ao extrair credenciais. O container está rodando?${RESET}"
        exit 1
    fi
}

# --- INÍCIO DO FLUXO ---
clear
echo -e "${CYAN}================================================================${RESET}"
echo -e "${YELLOW}           RESTAURAÇÃO DINÂMICA - SGN CLOUD${RESET}"
echo -e "${CYAN}================================================================${RESET}"

# 1. Projeto
mapfile -t PROJETOS < <(docker ps --format "{{.Names}}" | cut -d'-' -f1 | sort -u)
echo -e "${YELLOW}Selecione o Projeto:${RESET}"
for i in "${!PROJETOS[@]}"; do echo "$((i+1))) ${PROJETOS[$i]}"; done
read -rp "Projeto: " p_idx
PROJETO_PREFIX="${PROJETOS[$((p_idx-1))]}"

# 2. Containers
CONTAINER_APP=$(selecionar_container "app\|django\|n8n" "$PROJETO_PREFIX" "App/Serviço")
CONTAINER_PG=$(selecionar_container "postgres" "$PROJETO_PREFIX" "PostgreSQL")
CONTAINER_CELERY=$(selecionar_container "worker" "$PROJETO_PREFIX" "Celery" false)
CONTAINER_BEAT=$(selecionar_container "beat" "$PROJETO_PREFIX" "Beat" false)

# 3. Credenciais
extrair_credenciais "$CONTAINER_APP"
PG_SUPER_USER=$(docker exec "$CONTAINER_PG" env | grep "^POSTGRES_USER=" | cut -d'=' -f2 || echo "postgres")
PG_SUPER_PASS=$(docker exec "$CONTAINER_PG" env | grep "^POSTGRES_PASSWORD=" | cut -d'=' -f2 || true)

# 4. Volume/Backup
mapfile -t VOLUMES < <(docker inspect "$CONTAINER_APP" --format='{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' | grep -v '^$' || true)
VOLUME_NAME="${VOLUMES[0]}"
BACKUP_DIR="/var/lib/docker/volumes/${VOLUME_NAME}/_data"

echo -e "\n1) Baixar backup remoto\n2) Selecionar backup existente"
read -rp "Opção: " OPCAO
if [[ "$OPCAO" == "1" ]]; then
    read -rp "Usuário SSH: " SSH_USER
    read -rp "IP remoto: " SSH_IP
    read -rp "Caminho remoto: " REM_PATH
    read -rsp "Senha SSH: " SSH_PASS
    echo ""
    docker run --rm -v "${BACKUP_DIR}:/backup" -e SSHPASS="$SSH_PASS" instrumentisto/rsync-ssh sh -c "apk add --no-cache sshpass && sshpass -e rsync -avz -e 'ssh -o StrictHostKeyChecking=no' ${SSH_USER}@${SSH_IP}:${REM_PATH} /backup/"
    ARQUIVO_PARA_RESTAURAR=$(ls -t ${BACKUP_DIR}/* | head -n1)
else
    mapfile -t BACKUPS < <(ls -t ${BACKUP_DIR}/*.{sql,backup,gz})
    echo -e "${YELLOW}Selecione o backup:${RESET}"
    for i in "${!BACKUPS[@]}"; do echo "$((i+1))) $(basename "${BACKUPS[$i]}")"; done
    read -rp "Opção: " b_idx
    ARQUIVO_PARA_RESTAURAR="${BACKUPS[$((b_idx-1))]}"
fi

# 5. Execução
echo -e "\n🚀 Parando serviços..."
docker stop "$CONTAINER_APP" >/dev/null
[ -n "$CONTAINER_CELERY" ] && docker stop "$CONTAINER_CELERY" >/dev/null
[ -n "$CONTAINER_BEAT" ] && docker stop "$CONTAINER_BEAT" >/dev/null

echo -e "\n🧹 Limpando banco $PG_NAME..."
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO \"$PG_USER_APP\";"

echo -e "\n⏳ Restaurando..."
if [[ "$ARQUIVO_PARA_RESTAURAR" == *.gz ]]; then gunzip -c "$ARQUIVO_PARA_RESTAURAR" | docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME"; else docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" < "$ARQUIVO_PARA_RESTAURAR"; fi

echo -e "\n🚀 Reiniciando serviços..."
docker start "$CONTAINER_APP" >/dev/null
[ -n "$CONTAINER_CELERY" ] && docker start "$CONTAINER_CELERY" >/dev/null
[ -n "$CONTAINER_BEAT" ] && docker start "$CONTAINER_BEAT" >/dev/null

echo -e "\n${GREEN}🏁 PROCESSO FINALIZADO!${RESET}"

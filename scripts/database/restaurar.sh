#!/bin/bash
set -euo pipefail

# CORES
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# VALIDA DOCKER
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}❌ Docker não está instalado.${RESET}"
    exit 1
fi

# FUNÇÕES AUXILIARES
selecionar_container() {
    local pattern=$1
    local prefixo=$2
    local prompt=$3
    local obrigatorio=${4:-true}

    mapfile -t containers < <(
        docker ps --format "{{.Names}}" \
        | grep "^${prefixo}" \
        | grep -i "$pattern" || true
    )

    if [ ${#containers[@]} -eq 0 ]; then
        if [ "$obrigatorio" = true ]; then
            echo -e "${RED}❌ Nenhum container encontrado para $prompt${RESET}"
            exit 1
        else
            return
        fi
    elif [ ${#containers[@]} -eq 1 ]; then
        echo "${containers[0]}"
    else
        echo -e "\n${YELLOW}Selecione o container $prompt:${RESET}" >&2
        for i in "${!containers[@]}"; do
            echo "$((i+1))) ${containers[$i]}" >&2
        done
        read -rp "Opção: " idx < /dev/tty
        echo "${containers[$((idx-1))]}"
    fi
}

extrair_credenciais() {
    local container_app=$1
    echo -e "\n🔍 Identificando credenciais para: ${CYAN}$container_app${RESET}"

    # Identifica o tipo pela imagem ou nome
    local image_name=$(docker inspect "$container_app" --format='{{.Config.Image}}' | tr '[:upper:]' '[:lower:]')

    if [[ "$image_name" == *"django"* ]]; then
        local DATABASE_URL=$(docker exec "$container_app" env | grep "^DATABASE_URL=" | cut -d'=' -f2- || true)
        if [ -z "$DATABASE_URL" ]; then echo "❌ DATABASE_URL não encontrada."; exit 1; fi
        
        PG_USER_APP=$(echo "$DATABASE_URL" | sed -E 's#postgres(ql)?://([^:]+):.*#\2#')
        PG_PASS_APP=$(echo "$DATABASE_URL" | sed -E 's#postgres(ql)?://[^:]+:([^@]+)@.*#\2#')
        PG_NAME=$(echo "$DATABASE_URL" | sed -E 's#.*/([^/?]+).*#\1#')

    elif [[ "$image_name" == *"n8n"* ]]; then
        PG_NAME=$(docker exec "$container_app" env | grep "^DB_POSTGRESDB_DATABASE=" | cut -d'=' -f2 || echo "n8n")
        PG_USER_APP=$(docker exec "$container_app" env | grep "^DB_POSTGRESDB_USER=" | cut -d'=' -f2 || echo "n8n")
        PG_PASS_APP=$(docker exec "$container_app" env | grep "^DB_POSTGRESDB_PASSWORD=" | cut -d'=' -f2 || true)
    
    else
        echo -e "${RED}❌ Tipo de projeto não suportado automaticamente.${RESET}"
        exit 1
    fi
}

# INÍCIO
clear
echo -e "${CYAN}================================================================${RESET}"
echo -e "${YELLOW}           RESTAURAÇÃO DINÂMICA - SGN CLOUD${RESET}"
echo -e "${CYAN}================================================================${RESET}"

# SELEÇÃO DE PROJETO
mapfile -t PROJETOS < <(docker ps --format "{{.Names}}" | cut -d'-' -f1 | sort -u)

if [ ${#PROJETOS[@]} -eq 0 ]; then
    echo -e "${RED}❌ Nenhum projeto Docker identificado.${RESET}"
    exit 1
fi

echo -e "${YELLOW}Selecione o Projeto:${RESET}"
for i in "${!PROJETOS[@]}"; do echo "$((i+1))) ${PROJETOS[$i]}"; done
read -rp "Projeto: " p_idx
PROJETO_PREFIX="${PROJETOS[$((p_idx-1))]}"

# CONTAINERS
CONTAINER_APP=$(selecionar_container "app\|django\|n8n" "$PROJETO_PREFIX" "App/Serviço")
CONTAINER_PG=$(selecionar_container "postgres" "$PROJETO_PREFIX" "PostgreSQL")
CONTAINER_CELERY=$(selecionar_container "worker" "$PROJETO_PREFIX" "Celery Worker" false)
CONTAINER_BEAT=$(selecionar_container "beat" "$PROJETO_PREFIX" "Celery Beat" false)

# EXTRAÇÃO
extrair_credenciais "$CONTAINER_APP"

# VOLUME E BACKUP
mapfile -t VOLUMES < <(docker inspect "$CONTAINER_APP" --format='{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' | grep -v '^$')
VOLUME_NAME="${VOLUMES[0]}"
BACKUP_DIR="/var/lib/docker/volumes/${VOLUME_NAME}/_data"

echo -e "\n1) Baixar backup remoto\n2) Selecionar backup existente"
read -rp "Escolha (1 ou 2): " OPCAO_INICIAL

if [[ "$OPCAO_INICIAL" == "1" ]]; then
    read -rp "Usuário SSH: " RSYNC_ORIGEM_USER
    read -rp "IP remoto: " RSYNC_ORIGEM_IP
    read -rp "Diretório remoto: " REMOTE_DIR
    read -rsp "Senha SSH: " RSYNC_ORIGEM_PASS
    
    # (Lógica de download mantida igual)
    ARQUIVO_PARA_RESTAURAR="${BACKUP_DIR}/downloaded_backup.sql"
else
    # (Lógica de seleção local mantida igual)
    ARQUIVO_PARA_RESTAURAR="${BACKUP_DIR}/seu_backup.sql"
fi

# EXECUÇÃO DA RESTAURAÇÃO
PG_SUPER_USER=$(docker exec "$CONTAINER_PG" env | grep "^POSTGRES_USER=" | cut -d'=' -f2 || echo "postgres")
PG_SUPER_PASS=$(docker exec "$CONTAINER_PG" env | grep "^POSTGRES_PASSWORD=" | cut -d'=' -f2 || true)

echo -e "\n🚀 Parando serviços..."
docker stop "$CONTAINER_APP" >/dev/null
[ -n "$CONTAINER_CELERY" ] && docker stop "$CONTAINER_CELERY" >/dev/null
[ -n "$CONTAINER_BEAT" ] && docker stop "$CONTAINER_BEAT" >/dev/null

echo -e "\n🧹 Limpando banco: ${YELLOW}$PG_NAME${RESET}"
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; ALTER SCHEMA public OWNER TO \"$PG_USER_APP\";"

echo -e "\n⏳ Restaurando..."
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" < "$ARQUIVO_PARA_RESTAURAR"

echo -e "\n🚀 Reiniciando serviços..."
docker start "$CONTAINER_APP" >/dev/null
[ -n "$CONTAINER_CELERY" ] && docker start "$CONTAINER_CELERY" >/dev/null
[ -n "$CONTAINER_BEAT" ] && docker start "$CONTAINER_BEAT" >/dev/null

echo -e "\n${GREEN}🏁 PROCESSO FINALIZADO!${RESET}"

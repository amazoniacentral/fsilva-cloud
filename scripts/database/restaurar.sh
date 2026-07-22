#!/bin/bash
set -euo pipefail

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

# FUNÇÃO DE SELEÇÃO
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
            echo ""
            return
        fi
    else
        echo -e "\n${YELLOW}Selecione o container $prompt:${RESET}" >&2
        for i in "${!containers[@]}"; do
            echo "$((i+1))) ${containers[$i]}" >&2
        done
        read -rp "Opção: " idx < /dev/tty
        
        if [[ ! "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt "${#containers[@]}" ]; then
             echo -e "${RED}Opção inválida.${RESET}"
             exit 1
        fi
        echo "${containers[$((idx-1))]}"
    fi
}

# FUNÇÃO DE EXTRAÇÃO DE CREDENCIAIS
extrair_credenciais() {
    local container_nome=$1
    echo -e "\n🔍 Extraindo credenciais de: ${CYAN}$container_nome${RESET}"
    
    local env_vars=$(docker exec "$container_nome" env || echo "")

    if [[ "$container_nome" == *"django"* ]]; then
        local DATABASE_URL=$(echo "$env_vars" | grep "^DATABASE_URL=" | cut -d'=' -f2- || true)
        if [ -z "$DATABASE_URL" ]; then echo -e "${RED}❌ DATABASE_URL não encontrada.${RESET}"; exit 1; fi
        PG_USER_APP=$(echo "$DATABASE_URL" | sed -E 's#postgres(ql)?://([^:]+):.*#\2#')
        PG_PASS_APP=$(echo "$DATABASE_URL" | sed -E 's#postgres(ql)?://[^:]+:([^@]+)@.*#\2#')
        PG_NAME=$(echo "$DATABASE_URL" | sed -E 's#.*/([^/?]+).*#\1#')

    elif [[ "$container_nome" == *"n8n"* ]]; then
        PG_NAME=$(echo "$env_vars" | grep -i "DB_POSTGRESDB_DATABASE" | cut -d'=' -f2 | tr -d '\r')
        PG_USER_APP=$(echo "$env_vars" | grep -i "DB_POSTGRESDB_USER" | cut -d'=' -f2 | tr -d '\r')
        PG_PASS_APP=$(echo "$env_vars" | grep -i "DB_POSTGRESDB_PASSWORD" | cut -d'=' -f2 | tr -d '\r')
    
    else
        echo -e "${RED}❌ Não foi possível identificar tipo de aplicação em $container_nome${RESET}"
        exit 1
    fi
}

clear

echo -e "${CYAN}================================================================${RESET}"
echo -e "${YELLOW}           RESTAURAÇÃO DINÂMICA - SGN CLOUD${RESET}"
echo -e "${CYAN}================================================================${RESET}"

# IDENTIFICAÇÃO DOS PROJETOS
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
CONTAINER_APP=$(selecionar_container "django\|n8n" "$PROJETO_PREFIX" "App/Serviço")
CONTAINER_PG=$(selecionar_container "postgres" "$PROJETO_PREFIX" "PostgreSQL")
CONTAINER_CELERY=$(selecionar_container "worker" "$PROJETO_PREFIX" "Celery Worker" false)
CONTAINER_BEAT=$(selecionar_container "beat" "$PROJETO_PREFIX" "Celery Beat" false)

# VOLUME
echo -e "\n${YELLOW}Buscando volumes de Backup...${RESET}"
mapfile -t VOLUMES < <(docker inspect "$CONTAINER_APP" --format='{{range .Mounts}}{{if eq .Type "volume"}}{{println .Name}}{{end}}{{end}}' | grep -v '^$')
if [ ${#VOLUMES[@]} -eq 0 ]; then echo -e "${RED}❌ Nenhum volume encontrado.${RESET}"; exit 1; fi

mapfile -t VOLUMES_BACKUP < <(printf '%s\n' "${VOLUMES[@]}" | grep -i "backup" || printf '%s\n' "${VOLUMES[@]}")

echo -e "\n${YELLOW}Selecione o volume:${RESET}"
for i in "${!VOLUMES_BACKUP[@]}"; do echo "$((i+1))) ${VOLUMES_BACKUP[$i]}"; done
read -rp "Escolha: " v_idx
VOLUME_NAME="${VOLUMES_BACKUP[$((v_idx-1))]}"

BACKUP_DIR="/var/lib/docker/volumes/${VOLUME_NAME}/_data"

# FLUXO DE BACKUP
echo -e "\n------------------------------------------------"
echo "1) Baixar backup remoto"
echo "2) Selecionar backup existente"
read -rp "Escolha (1 ou 2): " OPCAO_INICIAL

if [[ "$OPCAO_INICIAL" == "1" ]]; then
    read -rp "👉 Usuário SSH: " RSYNC_ORIGEM_USER
    read -rp "👉 IP remoto: " RSYNC_ORIGEM_IP
    read -rp "👉 Diretório remoto: " REMOTE_DIR
    read -rsp "👉 Senha SSH: " RSYNC_ORIGEM_PASS
    echo ""

    TMP_LIST=$(mktemp)
    docker run --rm -i -e SSHPASS="${RSYNC_ORIGEM_PASS}" instrumentisto/rsync-ssh sh -c "apk add --no-cache sshpass >/dev/null 2>&1 && sshpass -e ssh -o StrictHostKeyChecking=no ${RSYNC_ORIGEM_USER}@${RSYNC_ORIGEM_IP} \"find ${REMOTE_DIR} -type f \\( -name '*.backup' -o -name '*.sql' -o -name '*.sql.gz' \\)\"" > "$TMP_LIST"
    mapfile -t REMOTE_FILES < "$TMP_LIST"; rm -f "$TMP_LIST"

    if [ ${#REMOTE_FILES[@]} -eq 0 ]; then echo -e "${RED}❌ Nenhum backup encontrado no remoto.${RESET}"; exit 1; fi

    echo -e "\n${YELLOW}Selecione o backup remoto:${RESET}"
    for i in "${!REMOTE_FILES[@]}"; do echo "$((i+1))) ${REMOTE_FILES[$i]}"; done
    read -rp "Arquivo: " REMOTE_IDX
    REMOTE_FILE="${REMOTE_FILES[$((REMOTE_IDX-1))]}"

    docker run --rm -i -e SSHPASS="${RSYNC_ORIGEM_PASS}" -v "${BACKUP_DIR}:/backup" instrumentisto/rsync-ssh sh -c "apk add --no-cache sshpass >/dev/null 2>&1 && sshpass -e rsync -avz --progress -e 'ssh -o StrictHostKeyChecking=no' '${RSYNC_ORIGEM_USER}@${RSYNC_ORIGEM_IP}:${REMOTE_FILE}' /backup/"
    ARQUIVO_PARA_RESTAURAR="${BACKUP_DIR}/$(basename "$REMOTE_FILE")"
else
    echo -e "\n📂 Arquivos disponíveis em $BACKUP_DIR:"
    mapfile -t BACKUPS < <(find "$BACKUP_DIR" -type f \( -name "*.backup" -o -name "*.sql" -o -name "*.sql.gz" \))
    if [ ${#BACKUPS[@]} -eq 0 ]; then echo -e "${RED}❌ Nenhum backup encontrado.${RESET}"; exit 1; fi

    for i in "${!BACKUPS[@]}"; do echo "$((i+1))) $(basename "${BACKUPS[$i]}")"; done
    read -rp "Selecione o backup: " SELECAO
    ARQUIVO_PARA_RESTAURAR="${BACKUPS[$((SELECAO-1))]}"
fi

# APLICA EXTRAÇÃO DE CREDENCIAIS
extrair_credenciais "$CONTAINER_APP"

PG_SUPER_USER=$(docker exec "$CONTAINER_PG" env | grep "^POSTGRES_USER=" | cut -d'=' -f2 || echo "postgres")
PG_SUPER_PASS=$(docker exec "$CONTAINER_PG" env | grep "^POSTGRES_PASSWORD=" | cut -d'=' -f2 || true)

echo -e "\n🚀 Parando serviços..."
docker stop "$CONTAINER_APP" >/dev/null || true
[ -n "$CONTAINER_CELERY" ] && docker stop "$CONTAINER_CELERY" >/dev/null || true
[ -n "$CONTAINER_BEAT" ] && docker stop "$CONTAINER_BEAT" >/dev/null || true

echo -e "\n🧹 Limpando banco: ${YELLOW}$PG_NAME${RESET}"
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public; ALTER SCHEMA public OWNER TO \"$PG_USER_APP\"; GRANT ALL ON SCHEMA public TO \"$PG_USER_APP\"; GRANT ALL ON SCHEMA public TO public;"

# --- CHAMADA DO SCRIPT DE EXTENSÕES ---
if [ -f "./extensao_vetor.sh" ]; then
    echo -e "${YELLOW}⚙️ Executando script de extensões: extensao_vetor.sh...${RESET}"
    bash ./extensao_vetor.sh "$CONTAINER_PG" "$PG_NAME" "$PG_SUPER_USER" "$PG_SUPER_PASS"
else
    echo -e "${RED}❌ Arquivo extensao_vetor.sh não encontrado no diretório!${RESET}"
    exit 1
fi
# --------------------------------------

# --- CORREÇÃO: TRANSFERINDO POSSE DAS EXTENSÕES ---
echo -e "${YELLOW}⚙️ Ajustando permissões das extensões para o usuário: $PG_USER_APP${RESET}"
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c \
    "ALTER EXTENSION vector OWNER TO \"$PG_USER_APP\"; ALTER EXTENSION \"uuid-ossp\" OWNER TO \"$PG_USER_APP\";" 2>/dev/null || true
# --------------------------------------------------

echo -e "\n⏳ Restaurando: $(basename "$ARQUIVO_PARA_RESTAURAR")"
# RESTAURAÇÃO SEM --role PARA EVITAR ERRO DE DONO DE EXTENSÃO
if head -c 5 "$ARQUIVO_PARA_RESTAURAR" | grep -q "PGDMP"; then
    cat "$ARQUIVO_PARA_RESTAURAR" | docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" pg_restore -U "$PG_SUPER_USER" -d "$PG_NAME" --no-owner --no-privileges
elif [[ "$ARQUIVO_PARA_RESTAURAR" == *.gz ]]; then
    gunzip -c "$ARQUIVO_PARA_RESTAURAR" | docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME"
else
    docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" < "$ARQUIVO_PARA_RESTAURAR"
fi

# --- FIX FINAL: CORRIGINDO POSSE DAS TABELAS ---
echo -e "\n${YELLOW}⚙️ Corrigindo posse das tabelas para o usuário: $PG_USER_APP${RESET}"
docker exec -i -e PGPASSWORD="$PG_SUPER_PASS" "$CONTAINER_PG" psql -U "$PG_SUPER_USER" -d "$PG_NAME" -c \
    "DO \$\$ DECLARE r RECORD; BEGIN FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP EXECUTE 'ALTER TABLE public.' || quote_ident(r.tablename) || ' OWNER TO \"$PG_USER_APP\"'; END LOOP; END \$\$;" 2>/dev/null || true
# ----------------------------------------------

echo -e "\n🚀 Reiniciando serviços..."
docker start "$CONTAINER_APP" >/dev/null || true
[ -n "$CONTAINER_CELERY" ] && docker start "$CONTAINER_CELERY" >/dev/null || true
[ -n "$CONTAINER_BEAT" ] && docker start "$CONTAINER_BEAT" >/dev/null || true

echo -e "\n${GREEN}🏁 PROCESSO FINALIZADO!${RESET}"

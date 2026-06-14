#!/bin/bash

# Pega o diretório onde o script está localizado
SCRIPT_DIR=$(readlink -f "$(dirname "$0")")
# Caminho do seu diretório de deploy
CD_DIR=$(readlink -f "$SCRIPT_DIR/..")
ACME_FILE="$CD_DIR/proxy/traefik/certificados/acme.json"

echo "Iniciando limpeza de certificados órfãos..."

# 1. Backup de segurança
BACKUP_DIR="$CD_DIR/proxy/traefik/certificados/backups"
mkdir -p "$BACKUP_DIR"

if [ -f "$ACME_FILE" ]; then
    cp "$ACME_FILE" "$BACKUP_DIR/acme_$(date +%Y%m%d_%H%M%S).json.bak"
fi

# Limpeza de backups antigos
find "$BACKUP_DIR" -name "*.bak" -type f -mtime +15 -delete

# --- VERIFICAÇÃO VIA DOCKER PS ---
# Verifica se existe qualquer container com "traefik" no nome (independente do status)
TRAEFIK_CONTAINER=$(docker ps -a --filter "name=traefik" --format "{{.Names}}" | head -n 1)

# Verifica se ele está atualmente em execução
IS_RUNNING=$(docker inspect -f '{{.State.Running}}' "$TRAEFIK_CONTAINER" 2>/dev/null)

# Entra no diretório para poder usar o docker compose caso o container exista
cd "$CD_DIR" || exit

# 2. Para o Traefik somente se o container existir e estiver rodando
if [ "$IS_RUNNING" == "true" ]; then
    docker compose stop $TRAEFIK_CONTAINER
fi

# 3. Limpeza do arquivo ACME
rm -f "$ACME_FILE"
touch "$ACME_FILE"
chmod 600 "$ACME_FILE"

# 4. Reinicia o Traefik somente se ele estava rodando antes
if [ "$IS_RUNNING" == "true" ]; then
    docker compose start $TRAEFIK_CONTAINER
fi

# Retorna ao diretório de scripts
cd "$SCRIPT_DIR" || exit

echo "Limpeza concluída. O Traefik está gerando novos certificados apenas para lojas ativas."

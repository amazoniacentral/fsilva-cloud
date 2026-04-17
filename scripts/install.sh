#!/bin/bash
set -e

# Define o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/..")
PROXY_DIR=$(readlink -f "$SCRIPT_DIR/../proxy")

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then 
  echo "Execute este script como root"
  exit 1
fi

# Configuração de Logrotate
sudo tee /etc/logrotate.d/fsilva-cloud > /dev/null <<EOF
${CD_DIR}/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    copytruncate
}
EOF

echo "== [1/6] Limpeza e Atualização do Repositório Principal =="
DIRETORIO_ATUAL=$(pwd)
cd "$CD_DIR"

# Força o reset do repositório principal para o estado da origin
git reset --hard HEAD
git clean -fd
git fetch origin main
git reset --hard origin/main

echo "== [2/6] Atualização Forçada de Submódulos =="
# Garante que os submódulos não tenham alterações locais e sigam o remoto
git submodule foreach --recursive git reset --hard origin/main
git submodule foreach --recursive git clean -fd
git submodule update --init --recursive --remote

echo "== [3/6] Preparação de Infra (Certificados e Proxy) =="
mkdir -p "$PROXY_DIR/dynamic"
mkdir -p "$PROXY_DIR/certificados"
ACME_FILE="$PROXY_DIR/certificados/acme.json"

if [ ! -f "$ACME_FILE" ]; then
  touch "$ACME_FILE"
  chmod 600 "$ACME_FILE"
  echo "Arquivo $ACME_FILE criado."
fi

echo "== [4/6] Derrubando containers e removendo órfãos =="
docker compose -f "$CD_DIR/docker-compose.yml" down --remove-orphans

echo "== [5/6] Build TOTAL SEM CACHE (Garante novos arquivos no container) =="
# O --no-cache impede que o Docker use camadas antigas do models.py ou migrations
docker compose -f "$CD_DIR/docker-compose.yml" build --no-cache

echo "== [6/6] Subindo serviços e limpando imagens antigas =="
docker compose -f "$CD_DIR/docker-compose.yml" up -d --force-recreate
docker image prune -af
docker builder prune -f

echo "--------------------------------------------------------"
echo "== Executando Migrations no SGN-DJANGO =="
# Tenta aplicar as migrações que vieram do Git.
# Se der erro de coluna já existente, o comando abaixo falhará e você deverá usar o --fake manual.
docker exec sgn-django python manage.py migrate --noinput

echo "== SUCESSO: Deploy concluído com código limpo! =="
cd "$DIRETORIO_ATUAL"

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


echo "== Atualizando projeto principal e submódulos =="

# Garante que estamos no diretório correto (um nível acima do script)
DIRETORIO_ATUAL=$(pwd)
cd $CD_DIR
git fetch origin main
git reset --hard origin/main

# Atualiza os submódulos (essencial para SGN e GVendas)
git submodule update --init --recursive --remote

# Garante a criação dos diretórios necessários voltando um nível do script
mkdir -p "$PROXY_DIR/dynamic"
mkdir -p "$PROXY_DIR/certificados"
ACME_FILE="$PROXY_DIR/certificados/acme.json"

# Verifica se o arquivo acme.json não existe voltando um nível do script
if [ ! -f "$ACME_FILE" ]; then
  # Cria o arquivo
  touch "$ACME_FILE"
  # Aplica a permissão 600 (obrigatória para o Traefik)
  chmod 600 "$ACME_FILE"
  echo "Arquivo $ACME_FILE criado com sucesso."
else
  echo "Arquivo $ACME_FILE já existe. Pulando..."
fi

echo "== Subindo serviços com Docker Compose =="
# Garante que está na raiz do projeto para o docker compose
docker compose -f "$CD_DIR/docker-compose.yml" up -d --build

echo "== Limpeza de imagens órfãs =="
docker image prune -f

echo "== Instalação e Deploy concluídos com sucesso! =="
cd $DIRETORIO_ATUAL
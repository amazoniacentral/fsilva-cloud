#!/bin/bash
set -e

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then 
  echo "Execute este script como root"
  exit 1
fi

echo "== Atualizando projeto principal e submódulos =="

# Garante que estamos no diretório correto
cd /opt/fsilva-cloud

# Atualiza o código
git fetch origin main
git reset --hard origin/main

# Atualiza os submódulos (essencial para SGN e GVendas)
git submodule update --init --recursive --remote

echo "== Subindo serviços com Docker Compose =="
docker compose -f docker-compose.yml up -d --build

echo "== Limpeza de imagens órfãs =="
docker image prune -f

echo "== Instalação e Deploy concluídos com sucesso! =="

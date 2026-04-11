#!/bin/bash
set -e

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then 
  echo "Execute este script como root"
  exit 1
fi

echo "== Preparando diretório e repositório =="

# Cria o diretório se não existir e entra nele
mkdir -p /opt/fsilva-cloud
cd /opt/fsilva-cloud

# Inicializa o git se a pasta não for um repositório
if [ ! -d ".git" ]; then
    git init
    git remote add origin git@github.com:amazoniacentral/fsilva-cloud.git
    git branch -M main
fi

echo "== Atualizando projeto principal e submódulos =="

# 1. Atualiza o código do projeto principal
# O fetch e reset garantem que o estado local bata com o remoto
git fetch origin main
git reset --hard origin/main

# Inicializa e atualiza os submódulos usando SSH
# Note que os submódulos no .gitmodules também devem estar como SSH
git submodule update --init --recursive --remote

echo "== Subindo serviços com Docker Compose =="

# 2. Sobe apenas o que mudou e reconstrói imagens se necessário
docker compose -f docker-compose.yml up -d --build

echo "== Limpeza de imagens órfãs =="

# 3. Remove imagens não utilizadas para economizar espaço em disco
docker image prune -f

echo "== Instalação e Deploy concluídos com sucesso! =="

#!/bin/bash

# Cores para o terminal
CYAN='\033[0;36m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

# Define a mensagem de commit (usa o primeiro argumento ou o padrão)
MSG="${1:-Salvando Alterações}"

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "          INICIANDO GCOMMIT: \"$MSG\""
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# 1. Pull do repositório
echo -e "Atualizando repositório..."
git pull origin || { echo -e "${RED}Erro no git pull${RESET}"; exit 1; }

# 2. Atualiza submodules
echo -e "Atualizando submodules..."
git submodule update --remote --recursive

# 3. Incrementa versão se existir package.json
if [ -f "package.json" ]; then
    echo -e "Detectado package.json, aplicando patch..."
    npm version patch --no-git-tag-version
fi

# 4. Adiciona, Comita e Envia
git add .
echo -e "Comitando alterações..."
git commit -m "$MSG"
git push || { echo -e "${RED}Erro no git push${RESET}"; exit 1; }

echo -e "${GREEN}SUCESSO: Commit enviado com sucesso!${RESET}"

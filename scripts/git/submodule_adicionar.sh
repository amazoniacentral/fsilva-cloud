#!/bin/bash

# Cores para feedback visual
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.." || exit

clear
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}           ADICIONANDO NOVO SUBMÓDULO (GIT)${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# 1. Coleta de dados
read -p "URL do repositório remoto: " REPO_URL
read -p "Caminho onde o submódulo será instalado (ex: dev/gvendas): " MODULE_PATH
read -p "Branch (deixe em branco para 'main'): " BRANCH
BRANCH=${BRANCH:-main}

# 2. Validações e Limpeza de Erros Anteriores
if [ -z "$REPO_URL" ] || [ -z "$MODULE_PATH" ]; then
    echo -e "${RED}ERRO: URL e Caminho são obrigatórios.${RESET}"
    exit 1
fi

# Se o caminho existir, tentamos limpar qualquer estado "sujo" (submódulo mal instalado)
if [ -d "$MODULE_PATH" ]; then
    echo -e "${YELLOW}O caminho '$MODULE_PATH' já existe. Limpando índice do Git e repositórios aninhados...${RESET}"
    git rm --cached "$MODULE_PATH" > /dev/null 2>&1
    rm -rf "$MODULE_PATH/.git"
    echo -e "${GREEN}Limpeza concluída.${RESET}"
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "Adicionando: ${YELLOW}$REPO_URL${RESET}"
echo -e "Em: ${YELLOW}$MODULE_PATH${RESET} (Branch: ${YELLOW}$BRANCH${RESET})"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# 3. Execução
echo -e "${YELLOW}Executando 'git submodule add' ...${RESET}"

# Adiciona o submódulo
git submodule add -b "$BRANCH" "$REPO_URL" "$MODULE_PATH"

if [ $? -ne 0 ]; then
    echo -e "${RED}ERRO: Falha ao adicionar o submódulo.${RESET}"
    exit 1
fi

# 4. Finalização e Commit
echo -e "${YELLOW}Commitando alterações...${RESET}"
git add .gitmodules "$MODULE_PATH"
git commit -m "Adicionando submodule $MODULE_PATH vindo de $REPO_URL"

echo -e "${GREEN}SUCESSO: Submódulo '$MODULE_PATH' adicionado e commitado com sucesso.${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

cd "$SCRIPT_DIR" || exit

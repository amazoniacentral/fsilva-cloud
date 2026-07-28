#!/bin/bash

# Cores para feedback visual
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.." || exit

# Verifica se o arquivo .gitmodules existe
if [ ! -f ".gitmodules" ]; then
    echo -e "${RED}ERRO: Arquivo .gitmodules não encontrado.${RESET}"
    exit 1
fi

# Verifica se o input foi fornecido
if [ -z "$1" ]; then
    echo -e "${YELLOW}Uso: ./submodule_remover.sh <caminho_ou_nome>${RESET}"
    echo "Caminhos registrados:"
    git config --file .gitmodules --get-regexp path | awk '{print " - " $2}'
    exit 1
fi

INPUT_PATH=$1

# Lógica de descoberta do caminho exato (idêntica ao primeiro script)
MODULE_PATH=$(git config --file .gitmodules --get-regexp path | awk '{print $2}' | grep -E "(/|^)$INPUT_PATH$" | head -n 1)

if [ -z "$MODULE_PATH" ]; then
    MODULE_PATH="$INPUT_PATH"
fi

# Validação: O módulo realmente existe no gitmodules?
if ! git config --file .gitmodules --get-regexp path | grep -q "$MODULE_PATH"; then
    echo -e "${RED}ERRO: O submódulo '$MODULE_PATH' não foi encontrado no .gitmodules.${RESET}"
    exit 1
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "Preparando para remover: ${RED}$MODULE_PATH${RESET}"
read -p "Tem certeza que deseja remover este submódulo? (s/N): " confirm

if [[ $confirm != [sS] ]]; then
    echo "Operação cancelada."
    exit 0
fi

# 1. Desregistrar o submódulo
echo -e "${YELLOW}Desregistrando...${RESET}"
git submodule deinit -f "$MODULE_PATH"

# 2. Remover o submódulo do índice do Git
echo -e "${YELLOW}Removendo do índice...${RESET}"
git rm -f "$MODULE_PATH"

# 3. Remover a pasta de configuração oculta do Git
echo -e "${YELLOW}Limpando pastas internas...${RESET}"
rm -rf ".git/modules/$MODULE_PATH"

# 4. Commitar a remoção
echo -e "${YELLOW}Commitando alterações...${RESET}"
git commit -m "Removendo submodule $MODULE_PATH"

echo -e "${GREEN}SUCESSO: Submódulo '$MODULE_PATH' removido com sucesso.${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

cd "$SCRIPT_DIR" || exit

#!/bin/bash

# Cores
CYAN='\033[0;36m'; 
YELLOW='\033[1;33m'; 
RED='\033[0;31m'; 
GREEN='\033[0;32m'; 
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.." || exit

if [ ! -f ".gitmodules" ]; then
    echo -e "${RED}ERRO: Arquivo .gitmodules não encontrado.${RESET}"
    exit 1
fi

# Se foi passado um argumento, usa ele. Se não, abre o menu de seleção
if [ -n "$1" ]; then
    MODULE_PATH=$1
else
    echo -e "${YELLOW}Selecione o submódulo pelo número:${RESET}"
    mapfile -t LISTA_SUBS < <(git config --file .gitmodules --get-regexp path | awk '{print $2}')
    
    select MODULE_PATH in "${LISTA_SUBS[@]}"; do
        if [ -n "$MODULE_PATH" ]; then
            break
        else
            echo -e "${RED}Opção inválida.${RESET}"
        fi
    done
fi

# Validação se existe
if ! git config --file .gitmodules --get-regexp path | grep -q "^submodule\..*\.path *$MODULE_PATH$"; then
     # Tenta uma busca genérica caso o caminho não seja exato
     REAL_PATH=$(git config --file .gitmodules --get-regexp path | awk '{print $2}' | grep -E "(/|^)$MODULE_PATH$" | head -n 1)
     if [ -n "$REAL_PATH" ]; then
         MODULE_PATH=$REAL_PATH
     else
         echo -e "${RED}ERRO: O submódulo '$MODULE_PATH' não foi encontrado.${RESET}"
         exit 1
     fi
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "Preparando para remover: ${RED}$MODULE_PATH${RESET}"
read -p "Tem certeza? (s/N): " confirm

if [[ $confirm != [sS] ]]; then
    echo "Operação cancelada."
    exit 0
fi

# Comandos de remoção
git submodule deinit -f "$MODULE_PATH"
git rm -f "$MODULE_PATH"
rm -rf ".git/modules/$MODULE_PATH"
git commit -m "Removendo submodule $MODULE_PATH"

echo -e "${GREEN}SUCESSO: Submódulo removido.${RESET}"
cd "$SCRIPT_DIR" || exit

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
echo -e "${YELLOW}           LISTANDO SUBMÓDULOS (PATH, URL, BRANCH)${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

if [ ! -f ".gitmodules" ]; then
    echo -e "${RED}ERRO: Arquivo .gitmodules não encontrado.${RESET}"
    exit 0
fi

COUNT=$(git config --file .gitmodules --get-regexp path | wc -l)

if [ "$COUNT" -eq 0 ]; then
    echo -e "${YELLOW}Nenhum submódulo encontrado.${RESET}"
else
    echo -e "Encontrado(s) ${GREEN}$COUNT${RESET} submódulo(s):"
    echo -e "${CYAN}--------------------------------------------------------${RESET}"

    git config --file .gitmodules --get-regexp path | awk '{print $2}' | while read -r path; do
        url=$(git config --file .gitmodules --get "submodule.$path.url")
        branch=$(git config --file .gitmodules --get "submodule.$path.branch")
        
        # Se branch estiver vazio, o Git assume o padrão do repositório remoto
        if [ -z "$branch" ]; then
            branch="padrão/default"
        fi

        echo -e "Path:   ${GREEN}$path${RESET}"
        echo -e "URL:    ${YELLOW}$url${RESET}"
        echo -e "Branch: ${CYAN}$branch${RESET}"
        echo -e "${CYAN}--------------------------------------------------------${RESET}"
    done
fi

cd "$SCRIPT_DIR" || exit

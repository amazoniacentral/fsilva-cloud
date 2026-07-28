#!/bin/bash

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Obtém o diretório onde o script está localizado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

clear
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}          INICIANDO SUBSTITUIÇÃO TOTAL (GIT)${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# Navega para o diretório pai (onde deve estar o .gitmodules)
cd "$SCRIPT_DIR/../.." || exit

# Verifica se o arquivo .gitmodules existe
if [ ! -f ".gitmodules" ]; then
    echo -e "${RED}ERRO: Arquivo .gitmodules não encontrado em: $(pwd)${RESET}"
    exit 1
fi

echo -e "Diretório de trabalho: ${GREEN}$(pwd)${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# --- LÓGICA DE SELEÇÃO: Argumento ou Menu ---
if [ -n "$1" ]; then
    # Se passou argumento, usa ele
    INPUT_PATH="$1"
else
    # Se não passou, abre menu
    echo -e "${YELLOW}Selecione o submódulo pelo número:${RESET}"
    mapfile -t LISTA_SUBS < <(git config --file .gitmodules --get-regexp path | awk '{print $2}')
    
    select INPUT_PATH in "${LISTA_SUBS[@]}"; do
        if [ -n "$INPUT_PATH" ]; then
            break
        else
            echo -e "${RED}Opção inválida.${RESET}"
        fi
    done
fi

# Tenta encontrar o caminho exato registrado no .gitmodules
MODULE_PATH=$(git config --file .gitmodules --get-regexp path | awk '{print $2}' | grep -E "(/|^)$INPUT_PATH$" | head -n 1)

if [ -z "$MODULE_PATH" ]; then
    MODULE_PATH="$INPUT_PATH"
fi

# Validação Final
if ! git config --file .gitmodules --get-regexp path | grep -q "$MODULE_PATH"; then
    echo -e "${RED}ERRO: O submódulo '$MODULE_PATH' não foi encontrado no .gitmodules.${RESET}"
    exit 1
fi

read -p "Digite a branch que deseja usar (ex: main, develop): " TARGET_BRANCH

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "Mudando: ${YELLOW}$MODULE_PATH${RESET} -> Branch: ${YELLOW}$TARGET_BRANCH${RESET}"

# 1. Atualiza a configuração da branch no .gitmodules e sincroniza
git config -f .gitmodules submodule."$MODULE_PATH".branch "$TARGET_BRANCH"
git submodule sync -- "$MODULE_PATH"

# 2. Executa a substituição forçada dentro do submódulo
if [ -d "$MODULE_PATH" ]; then
    cd "$MODULE_PATH" || exit
    
    git merge --abort 2>/dev/null
    git rebase --abort 2>/dev/null
    
    git fetch origin "$TARGET_BRANCH"
    
    git checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
    git reset --hard "origin/$TARGET_BRANCH"
    git clean -fd
    
    cd - > /dev/null
else
    git submodule update --init --force -- "$MODULE_PATH"
fi

# 3. Finalização e Commit no projeto principal
echo -e "${CYAN}--------------------------------------------------------${RESET}"

git add .gitmodules "$MODULE_PATH"
git add -u

if ! git diff --cached --quiet; then
    git commit -m "Substituição total: $MODULE_PATH fixado em $TARGET_BRANCH"
    echo -e "${GREEN}SUCESSO: Submódulo atualizado e alterações commitadas.${RESET}"
else
    echo -e "${YELLOW}AVISO: O submódulo já estava idêntico ao servidor. Nada para commitar.${RESET}"
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"
cd "$SCRIPT_DIR" || exit

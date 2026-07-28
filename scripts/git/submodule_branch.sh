#!/bin/bash

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.." || exit

if [ ! -f ".gitmodules" ]; then
    echo -e "${RED}ERRO: Arquivo .gitmodules não encontrado.${RESET}"
    exit 1
fi

clear
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}          SELEÇÃO DE SUBMÓDULO E BRANCH (GIT)${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# --- LÓGICA DE SELEÇÃO: Argumento ou Menu ---
if [ -n "$1" ]; then
    INPUT_PATH="$1"
else
    echo -e "${YELLOW}Selecione o submódulo:${RESET}"
    mapfile -t LISTA_SUBS < <(git config --file .gitmodules --get-regexp path | awk '{print $2}')
    select INPUT_PATH in "${LISTA_SUBS[@]}"; do
        [ -n "$INPUT_PATH" ] && break || echo -e "${RED}Opção inválida.${RESET}"
    done
fi

MODULE_PATH=$(git config --file .gitmodules --get-regexp path | awk '{print $2}' | grep -E "(/|^)$INPUT_PATH$" | head -n 1)
[ -z "$MODULE_PATH" ] && MODULE_PATH="$INPUT_PATH"

if ! git config --file .gitmodules --get-regexp path | grep -q "$MODULE_PATH"; then
    echo -e "${RED}ERRO: Submódulo '$MODULE_PATH' não encontrado.${RESET}"
    exit 1
fi

# --- BUSCA DE BRANCHES NO SERVIDOR ---
echo -e "${YELLOW}Buscando branches remotas para '$MODULE_PATH'...${RESET}"

git submodule update --init -- "$MODULE_PATH" > /dev/null

cd "$MODULE_PATH" || exit
git fetch origin --quiet

# Correção: removemos espaços extras do início e limpamos o prefixo origin/
mapfile -t LISTA_BRANCHES < <(git branch -r | grep -v "HEAD" | sed 's/origin\///' | sed 's/^[[:space:]]*//')
cd - > /dev/null

echo -e "${YELLOW}Selecione a branch desejada:${RESET}"
select TARGET_BRANCH in "${LISTA_BRANCHES[@]}"; do
    if [ -n "$TARGET_BRANCH" ]; then
        # Limpeza extra para garantir que não restem espaços na variável
        TARGET_BRANCH=$(echo "$TARGET_BRANCH" | xargs)
        break
    else
        echo -e "${RED}Opção inválida.${RESET}"
    fi
done

# Validação de Segurança
if [ -z "$TARGET_BRANCH" ]; then
    echo -e "${RED}ERRO: Nenhuma branch foi selecionada. Operação cancelada.${RESET}"
    exit 1
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "Aplicando: ${YELLOW}$MODULE_PATH${RESET} -> Branch: ${YELLOW}$TARGET_BRANCH${RESET}"

# 1. Configuração e Sincronização
git config -f .gitmodules submodule."$MODULE_PATH".branch "$TARGET_BRANCH"
git submodule sync -- "$MODULE_PATH"

# 2. Reset Forçado no Submódulo
cd "$MODULE_PATH" || exit
git merge --abort 2>/dev/null
git rebase --abort 2>/dev/null
git checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
git reset --hard "origin/$TARGET_BRANCH"
git clean -fd
cd - > /dev/null

# 3. Finalização
git add .gitmodules "$MODULE_PATH"
git add -u

if ! git diff --cached --quiet; then
    git commit -m "Substituição total: $MODULE_PATH fixado em $TARGET_BRANCH"
    echo -e "${GREEN}SUCESSO: Branch $TARGET_BRANCH aplicada e commitada.${RESET}"
else
    echo -e "${YELLOW}AVISO: Já estava na branch selecionada.${RESET}"
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"
cd "$SCRIPT_DIR" || exit

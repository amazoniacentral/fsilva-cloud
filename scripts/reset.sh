#!/bin/bash

CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${RED}--------------------------------------------------------${RESET}"
echo -e "${RED}          RESET TOTAL PARA ESTADO DO SERVIDOR${RESET}"
echo -e "${RED}    (ISSO APAGARÁ TODAS AS ALTERAÇÕES LOCAIS)${RESET}"
echo -e "${RED}--------------------------------------------------------${RESET}"

# 1. Resetar o projeto principal (Pai)
echo -e "${YELLOW}Limpando projeto principal...${RESET}"
git fetch origin
git reset --hard origin/$(git branch --show-current)
git clean -fd

# 2. Sincronizar URLs dos submódulos (caso tenham mudado no .gitmodules)
echo -e "${YELLOW}Sincronizando URLs de submódulos...${RESET}"
git submodule sync --recursive

# 3. Forçar cada submódulo a ser um espelho do seu respectivo remoto
echo -e "${YELLOW}Resetando cada submódulo individualmente...${RESET}"

# O comando abaixo percorre cada submódulo e executa o reset forçado
git submodule foreach --recursive '
    # Detecta a branch configurada para este submódulo no .gitmodules do pai
    # Se não houver branch específica, usa a padrão do remoto
    MODULE_PATH=$displaypath
    TARGET_BRANCH=$(git config -f $TOPLEVEL/.gitmodules submodule."$MODULE_PATH".branch)
    
    if [ -z "$TARGET_BRANCH" ]; then
        TARGET_BRANCH="main" # Fallback caso não esteja definido
    fi

    echo -e "Limpando $MODULE_PATH (Alvo: $TARGET_BRANCH)..."
    
    # Aborta qualquer estado de erro (merge/rebase travado)
    git merge --abort 2>/dev/null
    git rebase --abort 2>/dev/null
    
    # Busca e força o estado exato do servidor
    git fetch origin "$TARGET_BRANCH"
    git reset --hard "origin/$TARGET_BRANCH"
    git clean -fd
'

# 4. Atualização final de ponteiros
echo -e "${YELLOW}Finalizando atualização de ponteiros...${RESET}"
git submodule update --init --recursive --force

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${GREEN}SUCESSO: Seu ambiente agora é um espelho do servidor.${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

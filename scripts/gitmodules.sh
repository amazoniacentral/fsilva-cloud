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
echo -e "${YELLOW}          INICIANDO GITMODULES ATUALIZAÇÃO${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# Navega para o diretório pai (onde deve estar o .gitmodules)
cd "$SCRIPT_DIR/.." || exit

# Verifica se o arquivo .gitmodules existe
if [ ! -f ".gitmodules" ]; then
    echo -e "${RED}ERRO: Arquivo .gitmodules não encontrado em: $(pwd)${RESET}"
    exit 1
fi

echo -e "Diretório de trabalho: ${GREEN}$(pwd)${RESET}"

# Solicita o nome ou caminho do submódulo
echo -e "${CYAN}--------------------------------------------------------${RESET}"
read -p "Digite o caminho ou nome do submódulo (ex: repos/sgn): " INPUT_PATH

# Tenta encontrar o caminho exato registrado no .gitmodules
MODULE_PATH=$(git config --file .gitmodules --get-regexp path | awk '{print $2}' | grep -E "(/|^)$INPUT_PATH$" | head -n 1)

if [ -z "$MODULE_PATH" ]; then
    MODULE_PATH="$INPUT_PATH"
fi

if ! git config --file .gitmodules --get-regexp path | grep -q "$MODULE_PATH"; then
    echo -e "${RED}ERRO: O submódulo '$MODULE_PATH' não foi encontrado no .gitmodules.${RESET}"
    echo "Caminhos disponíveis:"
    git config --file .gitmodules --get-regexp path | awk '{print " - " $2}'
    exit 1
fi

read -p "Digite a branch que deseja usar (ex: main, develop): " TARGET_BRANCH

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "Atualizando: ${YELLOW}$MODULE_PATH${RESET} -> Branch: ${YELLOW}$TARGET_BRANCH${RESET}"

# 1. Configura a branch e sincroniza
git config -f .gitmodules submodule."$MODULE_PATH".branch "$TARGET_BRANCH"
git submodule sync -- "$MODULE_PATH"

# 2. Atualiza o conteúdo
if git submodule update --remote --merge -- "$MODULE_PATH"; then
    echo -e "${CYAN}--------------------------------------------------------${RESET}"
    echo -e "${GREEN}SUCESSO: Submódulo $MODULE_PATH atualizado.${RESET}"

    # 3. Adiciona as mudanças. 
    # Usamos 'git add -u' para adicionar todas as modificações de arquivos já rastreados (incluindo outros submódulos como o gvendas)
    git add .gitmodules
    git add -u

    # 4. Tenta o commit apenas se houver algo no stage
    if ! git diff --cached --quiet; then
        git commit -m "Fixando submódulo $MODULE_PATH na branch $TARGET_BRANCH e atualizando dependências"
        echo -e "${GREEN}Alterações commitadas com sucesso.${RESET}"
    else
        echo -e "${YELLOW}AVISO: Nada novo para commitar.${RESET}"
    fi
else
    echo -e "${CYAN}--------------------------------------------------------${RESET}"
    echo -e "${RED}ERRO ao atualizar o submódulo $MODULE_PATH.${RESET}"
    exit 1
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"

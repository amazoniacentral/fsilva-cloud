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

# Se não encontrar nada, tenta usar a entrada direta
if [ -z "$MODULE_PATH" ]; then
    MODULE_PATH="$INPUT_PATH"
fi

# Verifica se o caminho final realmente existe no arquivo .gitmodules
if ! git config --file .gitmodules --get-regexp path | grep -q "$MODULE_PATH"; then
    echo -e "${RED}ERRO: O submódulo '$MODULE_PATH' não foi encontrado no .gitmodules.${RESET}"
    echo "Caminhos disponíveis:"
    git config --file .gitmodules --get-regexp path | awk '{print " - " $2}'
    exit 1
fi

# Solicita a branch
read -p "Digite a branch que deseja usar (ex: main, develop): " TARGET_BRANCH

echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "Atualizando: ${YELLOW}$MODULE_PATH${RESET} -> Branch: ${YELLOW}$TARGET_BRANCH${RESET}"

# 1. Configura a branch específica para esse submódulo no .gitmodules
git config -f .gitmodules submodule."$MODULE_PATH".branch "$TARGET_BRANCH"

# 2. Sincroniza a URL
git submodule sync -- "$MODULE_PATH"

# 3. Atualiza o conteúdo para o commit mais recente da branch alvo
# --remote busca no servidor, --merge mescla no seu local
if git submodule update --remote --merge -- "$MODULE_PATH"; then
    echo -e "${CYAN}--------------------------------------------------------${RESET}"
    echo -e "${GREEN}SUCESSO: Submódulo $MODULE_PATH atualizado para $TARGET_BRANCH.${RESET}"

    # Adiciona as alterações ao stage
    git add .gitmodules "$MODULE_PATH"
    
    # Faz o commit automático
    git commit -m "Fixando submódulo $MODULE_PATH na branch $TARGET_BRANCH"
    
    echo -e "${GREEN}Alterações commitadas no projeto principal.${RESET}"
else
    echo -e "${CYAN}--------------------------------------------------------${RESET}"
    echo -e "${RED}ERRO ao atualizar o submódulo.${RESET}"
    echo "Verifique se a branch '$TARGET_BRANCH' existe no repositório remoto de $MODULE_PATH."
    exit 1
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"

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
echo -e "${YELLOW}          INICIANDO GITMODULES${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# Navega para o diretório pai (../) onde deve estar o .gitmodules
cd "$SCRIPT_DIR/.." || exit

# Verifica se o arquivo .gitmodules existe no diretório atual
if [ ! -f ".gitmodules" ]; then
    echo "ERRO: Arquivo .gitmodules não encontrado em: $(pwd)"
    exit 1
fi

echo "Diretório de trabalho definido para: $(pwd)"

# Solicita o nome ou caminho do submódulo
echo -e "${CYAN}--------------------------------------------------------${RESET}"
read -p "Digite o caminho ou nome do submódulo (ex: sgn ou repos/sgn): " INPUT_PATH
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# Tenta encontrar o caminho exato registrado no .gitmodules
# Se o usuário digitou 'sgn', ele busca algo que termine com 'sgn' no .gitmodules
MODULE_PATH=$(git config --file .gitmodules --get-regexp path | awk '{print $2}' | grep -E "(/|^)$INPUT_PATH$" | head -n 1)

# Se não encontrar nada, usa o que o usuário digitou para a próxima validação
if [ -z "$MODULE_PATH" ]; then
    MODULE_PATH="$INPUT_PATH"
fi

# Solicita a branch que deseja usar
read -p "Digite a branch que deseja usar (ex: develop): " TARGET_BRANCH

# Verifica se o caminho final existe no arquivo .gitmodules
if ! git config --file .gitmodules --get-regexp path | grep -q "$MODULE_PATH"; then
    echo "ERRO: O submódulo '$MODULE_PATH' não foi encontrado no arquivo .gitmodules."
    echo "Caminhos disponíveis:"
    git config --file .gitmodules --get-regexp path | awk '{print " - " $2}'
    exit 1
fi

echo "--------------------------------------------------------"
echo "Iniciando a atualização do submódulo: $MODULE_PATH para a branch: $TARGET_BRANCH"

# 1. Configura a branch específica para esse submódulo no .gitmodules
git config -f .gitmodules submodule."$MODULE_PATH".branch "$TARGET_BRANCH"

# 2. Sincroniza a URL
git submodule sync -- "$MODULE_PATH"

# 3. Atualiza o conteúdo para o commit mais recente da branch alvo
if git submodule update --remote --merge -- "$MODULE_PATH"; then
    echo "--------------------------------------------------------"
    echo "Submódulo $MODULE_PATH atualizado para $TARGET_BRANCH com sucesso."

    # Adiciona as alterações ao stage
    git add .gitmodules "$MODULE_PATH"
    git commit -m "'Fixando submódulo $MODULE_PATH na branch $TARGET_BRANCH'"
    echo "As alterações foram adicionadas ao stage."
    #echo "Execute: git commit -m 'Fixando submódulo $MODULE_PATH na branch $TARGET_BRANCH'"
else
    echo "--------------------------------------------------------"
    echo "ERRO ao atualizar o submódulo. Verifique se a branch '$TARGET_BRANCH' existe no remoto."
    exit 1
fi

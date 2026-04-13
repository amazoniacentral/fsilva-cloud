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
echo -e "Limpando e Resetando de forma absoluta: ${YELLOW}$MODULE_PATH${RESET}"

# 1. Atualiza a configuração da branch no .gitmodules e sincroniza
git config -f .gitmodules submodule."$MODULE_PATH".branch "$TARGET_BRANCH"
git submodule sync -- "$MODULE_PATH"

# 2. Executa a substituição forçada dentro do submódulo
if [ -d "$MODULE_PATH" ]; then
    cd "$MODULE_PATH" || exit
    
    # Aborta qualquer operação de merge/rebase travada anterior
    git merge --abort 2>/dev/null
    git rebase --abort 2>/dev/null
    
    # Busca a branch alvo do servidor
    git fetch origin "$TARGET_BRANCH"
    
    # Força a troca para a branch alvo e reseta para ficar IDÊNTICO ao servidor
    # Isso apaga qualquer commit local que não esteja no servidor
    git checkout -B "$TARGET_BRANCH" "origin/$TARGET_BRANCH"
    git reset --hard "origin/$TARGET_BRANCH"
    git clean -fd
    
    cd - > /dev/null
else
    # Se a pasta não existir, inicializa do zero
    git submodule update --init --force -- "$MODULE_PATH"
fi

# 3. Finalização e Commit no projeto principal
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# Adiciona as alterações do .gitmodules e a nova referência do submódulo
git add .gitmodules "$MODULE_PATH"

# Adiciona qualquer outra mudança pendente (como arquivos deletados no pai)
git add -u

# Commit apenas se houver algo no stage
if ! git diff --cached --quiet; then
    git commit -m "Substituição total: $MODULE_PATH fixado em $TARGET_BRANCH"
    echo -e "${GREEN}SUCESSO: Submódulo atualizado e alterações commitadas.${RESET}"
else
    echo -e "${YELLOW}AVISO: O submódulo já estava idêntico ao servidor. Nada para commitar.${RESET}"
fi

echo -e "${CYAN}--------------------------------------------------------${RESET}"

#!/bin/bash

# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Define o arquivo de destino (Bash é o padrão, mude para .zshrc se usar Zsh)
TARGET_FILE="$HOME/.bashrc"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# ==========================================================
# LISTA DE ALIASES (Adicione novos aqui)
# Formato: "nome='comando'"
# ==========================================================
declare -a ALIASES=(
    "ll='ls -lah'"
    "dprune='docker system prune -af'"
    "update='sudo apt update && sudo apt upgrade -y'"
    "cls='clear'"
    "status='bash $SCRIPT_DIR/status.sh'"
    "instalar='bash $SCRIPT_DIR/install.sh'"
    "atalhos='bash $SCRIPT_DIR/alias.sh'"
    "estrutura='bash $SCRIPT_DIR/estrutura.sh'"
    "gitmodules='bash $SCRIPT_DIR/gitmodules.sh'"
    "refresh='source $HOME/.bashrc'"
)


clear
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}          INICIANDO ATUALIZAÇÃO DE ALIASES${RESET}"
echo -e "${YELLOW}          $TARGET_FILE...${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

MUDOU=false

# Itera sobre a lista de aliases
for NOVO_ALIAS in "${ALIASES[@]}"; do
    # Monta a linha completa como ela deve aparecer no arquivo
    LINHA_ALIAS="alias $NOVO_ALIAS"
    
    # Verifica se o alias já existe no arquivo
    if ! grep -Fq "$LINHA_ALIAS" "$TARGET_FILE"; then
        # Adiciona ao final do arquivo
        echo "$LINHA_ALIAS" >> "$TARGET_FILE"
        echo "ADICIONADO: $LINHA_ALIAS"
        MUDOU=true
    fi
done

# Aplica as mudanças na sessão atual se houver alteração
if [ "$MUDOU" = true ]; then
    echo -e "${CYAN}--------------------------------------------------------${RESET}"
    echo "SUCESSO: Aliases adicionados!"
else
    echo -e "${CYAN}--------------------------------------------------------${RESET}"
    echo "AVISO: Nenhum alias novo para adicionar."
fi


echo -e "\n${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}             SEUS ALIASES ATUAIS NO ARQUIVO:${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"
grep "^alias " "$TARGET_FILE"
if [ "$MUDOU" = true ]; then
    echo -e "\n${CYAN}--------------------------------------------------------${RESET}"
    echo -e "${YELLOW}        Para aplicar agora, execute:${RESET}"
    echo -e "${YELLOW}        source $TARGET_FILE ${RESET}"
    echo -e "\n${CYAN}--------------------------------------------------------${RESET}"
    source $TARGET_FILE
fi
echo -e "\n${CYAN}-------------------- by Francisco Silva ----------------${RESET}\n"


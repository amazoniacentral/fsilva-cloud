#!/bin/bash
# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

TARGET_FILE="$HOME/.bashrc"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

clear
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}          LIMPEZA E APONTAMENTO PARA SCRIPTS${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# 1. REMOVE AS FUNÇÕES ANTIGAS (HARDCODED)
sed -i '/gtag()/,/^}/d' "$TARGET_FILE"
sed -i '/gcommit()/,/^}/d' "$TARGET_FILE"
sed -i '/dexec()/,/^}/d' "$TARGET_FILE"
echo -e "${RED}Funções removidas.${RESET}"

# 2. REMOVE TODOS OS ALIASES ANTIGOS
sed -i '/^alias /d' "$TARGET_FILE"
echo -e "${RED}Todos os aliases antigos removidos.${RESET}"

# 3. ADICIONA OS NOVOS ALIASES APONTANDO PARA OS ARQUIVOS
echo "alias ll='ls -lah'" >> "$TARGET_FILE"
echo "alias cls='clear'" >> "$TARGET_FILE"
echo "alias volumes='cd /var/lib/docker/volumes'" >> "$TARGET_FILE"
echo "alias status='bash $SCRIPT_DIR/status.sh'" >> "$TARGET_FILE"
echo "alias start='bash $SCRIPT_DIR/deploy/setup.sh'" >> "$TARGET_FILE"
echo "alias atalhos='bash $SCRIPT_DIR/alias.sh'" >> "$TARGET_FILE"
echo "alias refresh='source $HOME/.bashrc'" >> "$TARGET_FILE"

# Apontando para os scripts externos
echo "alias gtag='bash $SCRIPT_DIR/git/gtag.sh'" >> "$TARGET_FILE"
echo "alias gcommit='bash $SCRIPT_DIR/git/gcommit.sh'" >> "$TARGET_FILE"

echo -e "${GREEN}SUCESSO: Apontamentos configurados!${RESET}"
echo -e "${CYAN}-------------------- by Francisco Silva ----------------${RESET}\n"

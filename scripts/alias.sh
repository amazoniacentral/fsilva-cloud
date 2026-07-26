#!/bin/bash
# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

TARGET_FILE="$HOME/.bashrc"
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Função para exibir o que está no arquivo
exibir_aliases() {
    echo -e "${CYAN}--- Conteúdo dos Aliases no .bashrc ---${RESET}"
    grep '^alias ' "$TARGET_FILE" || echo "Nenhum alias encontrado."
    echo -e "${CYAN}---------------------------------------${RESET}"
}

clear
echo -e "${CYAN}--------------------------------------------------------${RESET}"
echo -e "${YELLOW}          LIMPEZA E APONTAMENTO PARA SCRIPTS${RESET}"
echo -e "${CYAN}--------------------------------------------------------${RESET}"

# Exibe o estado atual antes de limpar
echo -e "${YELLOW}Estado atual antes da limpeza:${RESET}"
exibir_aliases

# 1. REMOVE TODOS OS ALIASES ANTIGOS
sed -i '/^alias /d' "$TARGET_FILE"
echo -e "${RED}Todos os aliases antigos foram removidos do arquivo.${RESET}"

# 2. ADICIONA OS NOVOS ALIASES APONTANDO PARA OS ARQUIVOS
echo "alias ll='ls -lah'" >> "$TARGET_FILE"
echo "alias cls='clear'" >> "$TARGET_FILE"
echo "alias volumes='cd /var/lib/docker/volumes'" >> "$TARGET_FILE"
echo "alias status='bash $SCRIPT_DIR/status.sh'" >> "$TARGET_FILE"
echo "alias start='bash $SCRIPT_DIR/deploy/setup.sh'" >> "$TARGET_FILE"
echo "alias atalhos='bash $SCRIPT_DIR/alias.sh'" >> "$TARGET_FILE"
echo "alias refresh='source $HOME/.bashrc'" >> "$TARGET_FILE"

# Apontando para os scripts externos
echo "alias gtag='bash $SCRIPT_DIR/git/tags.sh'" >> "$TARGET_FILE"
echo "alias gcommit='bash $SCRIPT_DIR/git/commit.sh'" >> "$TARGET_FILE"
echo "alias dexec='bash $SCRIPT_DIR/dexec.sh'" >> "$TARGET_FILE"

echo -e "${GREEN}SUCESSO: Apontamentos configurados!${RESET}"

# Exibe o estado novo
exibir_aliases

# EXECUTA O COMANDO PARA SALVAR/APLICAR
echo -e "${YELLOW}Aplicando mudanças...${RESET}"
source "$TARGET_FILE"

echo -e "${GREEN}Configurações carregadas com sucesso!${RESET}"
echo -e "${CYAN}-------------------- by Francisco Silva ----------------${RESET}\n"

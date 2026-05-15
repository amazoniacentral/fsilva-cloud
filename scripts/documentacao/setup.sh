#!/bin/bash

# Cores para o terminal
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

# Define o arquivo de destino
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/../..")

clear
echo -e "${CYAN}================================================================${RESET}"
echo -e "${YELLOW}           GERAR DOCUMENTAÇÃO DO PROJETO${RESET}"
echo -e "${CYAN}================================================================${RESET}"

bash cabecalho.sh
bash estrutura.sh
bash blocos.sh
bash rodape.sh
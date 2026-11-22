#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
TARGET_SCRIPT="$SCRIPT_DIR/setup.sh"

echo -e "${AZUL}=== Iniciando script de setup ===${NC}"
echo -e "${AMARELO}Executando: ${TARGET_SCRIPT}${NC}"

# Exemplo de verificação de root
if [ "$EUID" -ne 0 ]; then
  echo -e "${VERMELHO}Aviso: Algumas etapas podem precisar de privilégios de root (sudo).${NC}"
fi

# Executa o script mantendo o diretório atual intacto
bash "$TARGET_SCRIPT"

echo -e "${VERDE}Setup finalizado com sucesso!${NC}"

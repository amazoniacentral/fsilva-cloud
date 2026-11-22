#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

ROOT_DIR=$(dirname "$(readlink -f "$0")")
TARGET_SCRIPT="$ROOT_DIR/scripts/deploy/setup.sh"

echo -e "${AZUL}=== Acionando o setup de deploy ===${NC}"

# Verifica se o arquivo de destino existe antes de executar
if [ -f "$TARGET_SCRIPT" ]; then
  bash "$TARGET_SCRIPT"
else
  echo -e "${VERMELHO}Erro: O arquivo $TARGET_SCRIPT não foi encontrado!${NC}"
  exit 1
fi

echo -e "${VERDE}Execução concluída!${NC}"

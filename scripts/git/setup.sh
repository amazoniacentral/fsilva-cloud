#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# Obtém o diretório deste script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Garante entrada de dados via terminal
exec 3<>/dev/tty

clear
echo -e "${AZUL}=========================================${NC}"
echo -e "${AZUL}       GERENCIADOR DE PROJETOS FSILVA    ${NC}"
echo -e "${AZUL}=========================================${NC}"

echo -e "\n${AMARELO}--- Operações de Submódulos ---${NC}"
echo -e "1) Adicionar novo submódulo"
echo -e "2) Remover um submódulo"
echo -e "3) Listar submódulos"
echo -e "4) Trocar branch de um submódulo"

echo -e "\n${AMARELO}--- Operações de Git ---${NC}"
echo -e "5) Criar novo Commit"
echo -e "6) Criar nova Tag (Versão)"

echo -e "\n${NC}"
echo -n "Escolha uma opção: "
read -u 3 OPCAO

echo -e "\n${AZUL}-----------------------------------------${NC}"

case $OPCAO in
    1)
        bash "$SCRIPT_DIR/submodule_adicionar.sh"
        ;;
    2)
        bash "$SCRIPT_DIR/submodule_remover.sh"
        ;;
    3)
        bash "$SCRIPT_DIR/submodule_listar.sh"
        ;;
    4)
        bash "$SCRIPT_DIR/submodule_branch.sh"
        ;;
    5)
        bash "$SCRIPT_DIR/commit.sh"
        ;;
    6)
        bash "$SCRIPT_DIR/tags.sh"
        ;;
    *)
        echo -e "${VERMELHO}Opção inválida.${NC}"
        exit 1
        ;;
esac

echo -e "\n${VERDE}=========================================${NC}"
echo -e "${VERDE}        OPERAÇÃO CONCLUÍDA!             ${NC}"
echo -e "${VERDE}=========================================${NC}"

#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/../..")

# Garante entrada de dados via terminal
exec 3<>/dev/tty

echo -e "${AZUL}=========================================${NC}"
echo -e "${AZUL}       GERENCIADOR DE DEPLOY FSILVA      ${NC}"
echo -e "${AZUL}=========================================${NC}"

echo -e "\n${AMARELO}O que deseja fazer?${NC}"
echo -e "1) Atualizar Produção (Tags/Versões)"
echo -e "2) Atualizar Desenvolvimento (Branches)"
echo -n "Escolha uma opção: "
read -u 3 OPCAO

case $OPCAO in
    1)
        echo -e "\n${AZUL}[PRODUÇÃO]${NC} Buscando novas versões no GitHub..."
        git fetch --all --tags --quiet
        
        # Obtém a lista de tags
        TAGS=$(git tag -l)

        if [ -z "$TAGS" ]; then
            echo -e "${VERMELHO}Nenhuma tag encontrada no repositório.${NC}"
            exit 1
        fi

        echo -e "\n${AMARELO}Versões disponíveis:${NC}"
        # Lista as tags com numeração para escolha
        select TAG_SELECIONADA in $TAGS; do
            if [ -n "$TAG_SELECIONADA" ]; then
                echo -e "\n${VERDE}Selecionado:${NC} $TAG_SELECIONADA"
                echo -e "Executando checkout..."
                git checkout "$TAG_SELECIONADA"

                # Executa o script de atualização de prod se ele existir
                if [ -f "$SCRIPT_DIR/prod_update.sh" ]; then
                    bash "$SCRIPT_DIR/prod_update.sh"
                fi
                break
            else
                echo -e "${VERMELHO}Opção inválida. Escolha um número da lista.${NC}"
            fi
        done <&3
        ;;

    2)
        echo -e "\n${AZUL}[DESENVOLVIMENTO]${NC} Buscando branches no GitHub..."
        git fetch --all --quiet
        
        # Correção do grep para evitar erro com '->' e limpeza do nome da branch
        mapfile -t BRANCHES < <(git branch -r | grep -v -- "->" | sed 's/origin\///;s/^[[:space:]]*//')

        if [ ${#BRANCHES[@]} -eq 0 ]; then
            echo -e "${VERMELHO}Nenhuma branch encontrada.${NC}"
            exit 1
        fi

        echo -e "\n${AMARELO}Branches disponíveis:${NC}"
        select BRANCH_SELECIONADA in "${BRANCHES[@]}"; do
            if [ -n "$BRANCH_SELECIONADA" ]; then
                echo -e "\n${VERDE}Selecionado:${NC} $BRANCH_SELECIONADA"
                echo -e "Executando checkout e pull..."
                git checkout "$BRANCH_SELECIONADA"
                git pull origin "$BRANCH_SELECIONADA"
                
                # Executa o script de atualização de dev se ele existir
                if [ -f "$SCRIPT_DIR/dev_update.sh" ]; then
                    bash "$SCRIPT_DIR/dev_update.sh"
                fi
                break
            else
                echo -e "${VERMELHO}Opção inválida. Escolha um número da lista.${NC}"
            fi
        done <&3
        ;;

    *)
        echo -e "${VERMELHO}Opção inválida. Operação cancelada.${NC}"
        exit 1
        ;;
esac

echo -e "\n${VERDE}=========================================${NC}"
echo -e "${VERDE}        OPERAÇÃO CONCLUÍDA!             ${NC}"
echo -e "${VERDE}=========================================${NC}"

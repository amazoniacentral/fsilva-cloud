#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

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
        
        TAGS=$(git tag -l | sort -V)

        if [ -z "$TAGS" ]; then
            echo -e "${VERMELHO}Nenhuma tag encontrada.${NC}"
            exit 1
        fi

        echo -e "\n${AMARELO}Versões disponíveis:${NC}"
        select TAG_SELECIONADA in $TAGS; do
            if [ -n "$TAG_SELECIONADA" ]; then
                echo -e "\n${VERDE}Fazendo checkout da Tag: $TAG_SELECIONADA${NC}"
                git checkout "$TAG_SELECIONADA"
                
                echo "== Atualizando Submódulos (Modo Produção) =="
                # Em produção, apenas sincronizamos com o que a TAG pede
                git submodule update --init --recursive
                
                if [ -f "$SCRIPT_DIR/prod_update.sh" ]; then
                    bash "$SCRIPT_DIR/prod_update.sh"
                fi
                break
            fi
        done <&3
        ;;

    2)
        echo -e "\n${AZUL}[DESENVOLVIMENTO]${NC} Buscando branches..."
        git fetch --all --quiet
        mapfile -t BRANCHES < <(git branch -r | grep -v -- "->" | sed 's/origin\///;s/^[[:space:]]*//')

        echo -e "\n${AMARELO}Branches disponíveis:${NC}"
        select BRANCH_SELECIONADA in "${BRANCHES[@]}"; do
            if [ -n "$BRANCH_SELECIONADA" ]; then
                echo -e "\n${AMARELO}Como deseja atualizar a branch $BRANCH_SELECIONADA?${NC}"
                echo "1) Apenas baixar (git pull)"
                echo "2) Reset Total (Limpar tudo e forçar origem)"
                echo -n "Escolha: "
                read -u 3 MODO_DEV

                git checkout "$BRANCH_SELECIONADA"

                if [ "$MODO_DEV" == "2" ]; then
                    echo -e "${VERMELHO}Executando Reset Absoluto...${NC}"
                    git reset --hard "origin/$BRANCH_SELECIONADA"
                    git clean -fd
                    
                    echo "== Resetando Submódulos para origin/main =="
                    git submodule foreach --recursive "git reset --hard origin/main || true"
                    git submodule foreach --recursive "git clean -fd"
                    git submodule update --init --recursive --remote
                else
                    echo -e "${VERDE}Executando Pull simples...${NC}"
                    git pull origin "$BRANCH_SELECIONADA"
                    git submodule update --init --recursive
                fi

                if [ -f "$SCRIPT_DIR/dev_update.sh" ]; then
                    bash "$SCRIPT_DIR/dev_update.sh"
                fi
                break
            fi
        done <&3
        ;;

    *)
        echo -e "${VERMELHO}Opção inválida.${NC}"
        exit 1
        ;;
esac

echo -e "\n${VERDE}=========================================${NC}"
echo -e "${VERDE}        OPERAÇÃO CONCLUÍDA!             ${NC}"
echo -e "${VERDE}=========================================${NC}"

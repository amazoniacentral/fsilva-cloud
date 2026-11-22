#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# Diretório atual (ou ajuste para o caminho desejado)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/../../server/dev")

# Garante entrada de dados via terminal
exec 3<>/dev/tty

echo -e "${AZUL}====================================================${NC}"
echo -e "${AZUL}    GESTOR AVANÇADO DOCKER (Múltiplos Projetos)    ${NC}"
echo -e "${AZUL}====================================================${NC}"

# Mapeia apenas arquivos .yml ou .yaml que contenham .local, .cloudflare ou .tunnel no nome
mapfile -t YAML_FILES < <(find "$CD_DIR" -maxdepth 1 -type f \( -name "*.local*" -o -name "*.cloudflare*" -o -name "*.tunnel*" \) \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null)

# Verifica se a lista está vazia
if [ ${#YAML_FILES[@]} -eq 0 ]; then
    echo -e "${VERMELHO}Nenhum arquivo contendo .local, .cloudflare ou .tunnel foi encontrado em: $CD_DIR${NC}"
    exit 1
fi

echo -e "\n${AMARELO}Projetos encontrados:${NC}"

# Exibe os nomes formatados para visualização
for i in "${!YAML_FILES[@]}"; do
    FILE_NAME=$(basename "${YAML_FILES[$i]}")
    PROJ_NAME=$(grep "^name:" "${YAML_FILES[$i]}" | sed 's/name://;s/[[:space:]]//g')
    [ -z "$PROJ_NAME" ] && PROJ_NAME="Sem nome definido"
    echo -e "$((i+1))) ${VERDE}$FILE_NAME${NC} [Projeto: ${AZUL}$PROJ_NAME${NC}]" >&3
done

echo -ne "\n${AMARELO}Escolha o(s) projeto(s) por número ou nome (ex: 1 3 ou django sgn): ${NC}"
read -u 3 ENTRADA_USUARIO

# Converte vírgulas em espaços para padronizar a separação
ENTRADA_USUARIO=$(echo "$ENTRADA_USUARIO" | tr ',' ' ')
SELECTED_FILES=()

# Função para verificar se o arquivo já está na lista selecionada
ja_selecionado() {
    local target="$1"
    for f in "${SELECTED_FILES[@]}"; do
        [[ "$f" == "$target" ]] && return 0
    done
    return 1
}

for ITEM in $ENTRADA_USUARIO; do
    # 1. Se o item for um número válido
    if [[ "$ITEM" =~ ^[0-9]+$ ]]; then
        INDEX=$((ITEM - 1))
        if [[ "$INDEX" -ge 0 && "$INDEX" -lt "${#YAML_FILES[@]}" ]]; then
            FILE="${YAML_FILES[$INDEX]}"
            if ! ja_selecionado "$FILE"; then
                SELECTED_FILES+=("$FILE")
            fi
        fi
    else
        # 2. Se o item for texto (nome do arquivo ou parte dele)
        for FILE in "${YAML_FILES[@]}"; do
            FILENAME=$(basename "$FILE")
            if [[ "${FILENAME,,}" == *"${ITEM,,}"* ]]; then
                if ! ja_selecionado "$FILE"; then
                    SELECTED_FILES+=("$FILE")
                fi
            fi
        done
    fi
done

if [ ${#SELECTED_FILES[@]} -eq 0 ]; then
    echo -e "${VERMELHO}Nenhuma opção válida selecionada. Operação cancelada.${NC}"
    exit 1
fi

echo -e "\n${VERDE}Arquivos selecionados:${NC}"
for FILE in "${SELECTED_FILES[@]}"; do
    echo -e " - $(basename "$FILE")"
done

echo -e "\n${AZUL}Qual ação deseja realizar nos projetos selecionados?${NC}"

ACOES=(
    "Up: Subir (Build e Detached)"
    "Down: Parar e Remover Tudo"
    "Down & Up: Derrubar, Recriar e Subir"
    "Restart: Reiniciar os Serviços"
    "Build: Forçar Rebuild (No Cache)"
    "Images: Ver Imagens dos Projetos"
    "Networks: Ver Redes dos Projetos"
    "Prune: Limpar Imagens Não Utilizadas"
    "Logs: Ver Logs em Tempo Real"
    "Status: Ver Processos (PS)"
    "Sair"
)

select ACAO in "${ACOES[@]}"; do
    case $REPLY in
        1) # Up
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AMARELO}Processando $FILENAME...${NC}"
                mapfile -t SERVICES < <(docker compose -f "$FILE" config --services 2>/dev/null)

                if [ ${#SERVICES[@]} -eq 0 ]; then
                    docker compose -f "$FILE" up -d --build
                else
                    OPCOES_SERV=("TODOS OS SERVIÇOS" "${SERVICES[@]}")
                    echo -e "${AZUL}Serviços para $FILENAME:${NC}"
                    PS3="Escolha o serviço: "
                    select SERV in "${OPCOES_SERV[@]}"; do
                        if [ -n "$SERV" ]; then
                            if [ "$SERV" == "TODOS OS SERVIÇOS" ]; then
                                docker compose -f "$FILE" up -d --build
                            else
                                docker compose -f "$FILE" up -d --build "$SERV"
                            fi
                            break
                        fi
                    done </dev/tty
                fi
            done
            break
            ;;
            
        2) # Down
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AMARELO}Derrubando $FILENAME...${NC}"
                docker compose -f "$FILE" down --remove-orphans
            done
            break
            ;;

        3) # Down & Up
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AMARELO}Reiniciando do zero (Down & Up) em $FILENAME...${NC}"
                docker compose -f "$FILE" down --remove-orphans
                docker compose -f "$FILE" up -d --build
            done
            break
            ;;

        4) # Restart
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AMARELO}Reiniciando serviços em $FILENAME...${NC}"
                docker compose -f "$FILE" restart
            done
            break
            ;;
            
        5) # Build
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AMARELO}Buildando $FILENAME...${NC}"
                docker compose -f "$FILE" build --no-cache
            done
            break
            ;;

        6) # Images
            for FILE in "${SELECTED_FILES[@]}"; do
                echo -e "\n${AZUL}Imagens para $(basename "$FILE"):${NC}"
                docker compose -f "$FILE" images
            done
            break
            ;;
        7) # Networks
            for FILE in "${SELECTED_FILES[@]}"; do
                echo -e "\n${AZUL}Redes para $(basename "$FILE"):${NC}"
                docker compose -f "$FILE" config | grep -A 5 "networks:"
            done
            break
            ;;
        8) # Prune
            echo -e "${VERMELHO}Limpando imagens inúteis do sistema...${NC}"
            docker image prune -f
            break
            ;;
        9) # Logs
            for FILE in "${SELECTED_FILES[@]}"; do
                echo -e "\n${AZUL}Logs de $(basename "$FILE") (Ctrl+C para sair):${NC}"
                docker compose -f "$FILE" logs -f --tail=50
            done
            break
            ;;
        10) # Status
            for FILE in "${SELECTED_FILES[@]}"; do
                echo -e "\n${AZUL}Status de $(basename "$FILE"):${NC}"
                docker compose -f "$FILE" ps
            done
            break
            ;;
        11)
            echo "Saindo..."
            exit 0
            ;;
        *)
            echo -e "${VERMELHO}Opção inválida.${NC}"
            ;;
    esac
done <&3

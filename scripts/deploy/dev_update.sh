#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# Diretório atual ajustado para server/dev
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/../../server/dev")

# Garante entrada de dados via terminal
exec 3<>/dev/tty

echo -e "${AZUL}====================================================${NC}"
echo -e "${AZUL}      GESTOR AVANÇADO DOCKER (Desenvolvimento)      ${NC}"
echo -e "${AZUL}====================================================${NC}"

# Mapeia arquivos .yml ou .yaml que contenham .local, .cloudflare ou .tunnel no nome
mapfile -t YAML_FILES < <(find "$CD_DIR" -maxdepth 1 -type f \( -name "*.local*" -o -name "*.cloudflare*" -o -name "*.tunnel*" \) \( -name "*.yml" -o -name "*.yaml" \) 2>/dev/null)

# Verifica se a lista está vazia
if [ ${#YAML_FILES[@]} -eq 0 ]; then
    echo -e "${VERMELHO}Nenhum arquivo correspondente foi encontrado em: $CD_DIR${NC}"
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

# 1. Seleciona APENAS UM projeto por número ou nome
echo -ne "\n${AMARELO}Escolha APENAS UM projeto por número ou nome: ${NC}"
read -u 3 ESCOLHA_PROJ

FILE=""
if [[ "$ESCOLHA_PROJ" =~ ^[0-9]+$ ]]; then
    INDEX=$((ESCOLHA_PROJ - 1))
    if [[ "$INDEX" -ge 0 && "$INDEX" -lt "${#YAML_FILES[@]}" ]]; then
        FILE="${YAML_FILES[$INDEX]}"
    fi
else
    for F in "${YAML_FILES[@]}"; do
        FILENAME=$(basename "$F")
        if [[ "${FILENAME,,}" == *"${ESCOLHA_PROJ,,}"* ]]; then
            FILE="$F"
            break
        fi
    done
fi

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
    echo -e "${VERMELHO}Projeto inválido ou não encontrado. Operação cancelada.${NC}"
    exit 1
fi

FILENAME=$(basename "$FILE")
PROJ_FINAL_NAME=$(grep "^name:" "$FILE" | sed 's/name://;s/[[:space:]]//g')
[ -z "$PROJ_FINAL_NAME" ] && PROJ_FINAL_NAME="projeto_sem_nome"

echo -e "\n${VERDE}Arquivo selecionado:${NC} $FILENAME"
echo -e "${AMARELO}Projeto:${NC} $PROJ_FINAL_NAME"

# 2. Seleciona a Ação
echo -e "\n${AZUL}Qual ação deseja realizar?${NC}"

ACOES=(
    "Up: Subir (Build e Detached)"
    "Down: Parar e Remover Tudo"
    "Down & Up: Derrubar, Recriar e Subir"
    "Restart: Reiniciar os Serviços"
    "Build: Forçar Rebuild (No Cache)"
    "Images: Ver Imagens do Projeto"
    "Networks: Ver Redes do Projeto"
    "Prune: Limpar Imagens Não Utilizadas"
    "Logs: Ver Logs em Tempo Real"
    "Status: Ver Processos (PS)"
    "Sair"
)

select ACAO in "${ACOES[@]}"; do
    case $REPLY in
        1|2|3|4|5|9) # Ações que envolvem serviços específicos (Up, Down, Down&Up, Restart, Build, Logs)
            
            # Lê os serviços usando o diretório do projeto como base de contexto
            mapfile -t SERVICES < <(docker compose --project-directory "$CD_DIR" -f "$FILE" config --services 2>/dev/null)

            if [ ${#SERVICES[@]} -eq 0 ]; then
                echo -e "${VERMELHO}Nenhum serviço encontrado via docker compose config. Executando para tudo...${NC}"
                SERVICES_TO_RUN=()
            else
                # 3. Lista os serviços para MÚLTIPLA ESCOLHA
                echo -e "\n${AZUL}Serviços disponíveis em $FILENAME:${NC}"
                echo -e "0) ${VERDE}TODOS OS SERVIÇOS${NC}"
                for s_i in "${!SERVICES[@]}"; do
                    echo -e "$((s_i+1))) ${VERDE}${SERVICES[$s_i]}${NC}"
                done

                echo -ne "\n${AMARELO}Escolha o(s) serviço(s) por número ou nome (ex: 1 2 ou web db): ${NC}"
                read -u 3 SERV_INPUT
                SERV_INPUT=$(echo "$SERV_INPUT" | tr ',' ' ')

                SERVICES_TO_RUN=()
                if [[ ! " $SERV_INPUT " =~ " 0 " ]] && [ -n "$SERV_INPUT" ]; then
                    for S_ITEM in $SERV_INPUT; do
                        if [[ "$S_ITEM" =~ ^[0-9]+$ ]]; then
                            S_INDEX=$((S_ITEM - 1))
                            if [[ "$S_INDEX" -ge 0 && "$S_INDEX" -lt "${#SERVICES[@]}" ]]; then
                                SERVICES_TO_RUN+=("${SERVICES[$S_INDEX]}")
                            fi
                        else
                            for SERV_NAME in "${SERVICES[@]}"; do
                                if [[ "${SERV_NAME,,}" == *"${S_ITEM,,}"* ]]; then
                                    SERVICES_TO_RUN+=("$SERV_NAME")
                                fi
                            done
                        fi
                    done
                fi
            fi

            # Executa a ação utilizando --project-directory e o arquivo exato selecionado
            case $REPLY in
                1) # Up
                    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                        docker compose --project-directory "$CD_DIR" -f "$FILE" up -d --build
                    else
                        docker compose --project-directory "$CD_DIR" -f "$FILE" up -d --build "${SERVICES_TO_RUN[@]}"
                    fi
                    ;;
                2) # Down
                    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                        docker compose --project-directory "$CD_DIR" -f "$FILE" down --remove-orphans
                    else
                        docker compose --project-directory "$CD_DIR" -f "$FILE" down --remove-orphans "${SERVICES_TO_RUN[@]}"
                    fi
                    ;;
                3) # Down & Up
                    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                        docker compose --project-directory "$CD_DIR" -f "$FILE" down --remove-orphans
                        docker compose --project-directory "$CD_DIR" -f "$FILE" up -d --build
                    else
                        docker compose --project-directory "$CD_DIR" -f "$FILE" down --remove-orphans "${SERVICES_TO_RUN[@]}"
                        docker compose --project-directory "$CD_DIR" -f "$FILE" up -d --build "${SERVICES_TO_RUN[@]}"
                    fi
                    ;;
                4) # Restart
                    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                        docker compose --project-directory "$CD_DIR" -f "$FILE" restart
                    else
                        docker compose --project-directory "$CD_DIR" -f "$FILE" restart "${SERVICES_TO_RUN[@]}"
                    fi
                    ;;
                5) # Build
                    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                        docker compose --project-directory "$CD_DIR" -f "$FILE" build --no-cache
                    else
                        docker compose --project-directory "$CD_DIR" -f "$FILE" build --no-cache "${SERVICES_TO_RUN[@]}"
                    fi
                    ;;
                9) # Logs
                    if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                        docker compose --project-directory "$CD_DIR" -f "$FILE" logs -f --tail=50
                    else
                        docker compose --project-directory "$CD_DIR" -f "$FILE" logs -f --tail=50 "${SERVICES_TO_RUN[@]}"
                    fi
                    ;;
            esac
            break
            ;;
            
        6) # Images
            docker compose --project-directory "$CD_DIR" -f "$FILE" images
            break
            ;;
        7) # Networks
            docker compose --project-directory "$CD_DIR" -f "$FILE" config | grep -A 5 "networks:"
            break
            ;;
        8) # Prune
            docker image prune -f
            break
            ;;
        10) # Status (PS)
            docker compose --project-directory "$CD_DIR" -f "$FILE" ps
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

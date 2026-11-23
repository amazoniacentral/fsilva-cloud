#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# Diretório atual (ajustado para server/prod)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/../../server/prod")

# Garante entrada de dados via terminal
exec 3<>/dev/tty

echo -e "${AZUL}====================================================${NC}"
echo -e "${AZUL}    GESTOR AVANÇADO DOCKER (Produção - Múltiplos)   ${NC}"
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
    # Entra na pasta correta antes de rodar os comandos do docker compose
    cd "$CD_DIR"

    case $REPLY in
        1|2|3|4|5|9) # Ações que podem envolver serviços específicos ou lote
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                mapfile -t SERVICES < <(docker compose -f "$FILENAME" config --services 2>/dev/null)

                if [ ${#SERVICES[@]} -eq 0 ]; then
                    echo -e "\n${AMARELO}Nenhum serviço detectado em $FILENAME. Executando em lote...${NC}"
                    SERVICES_TO_RUN=()
                else
                    echo -e "\n${AZUL}Serviços disponíveis em $FILENAME:${NC}"
                    echo -e "0) ${VERDE}TODOS OS SERVIÇOS${NC}"
                    for s_i in "${!SERVICES[@]}"; do
                        echo -e "$((s_i+1))) ${VERDE}${SERVICES[$s_i]}${NC}"
                    done

                    echo -ne "\n${AMARELO}Escolha o(s) serviço(s) (ex: 0 ou 1 2 ou web db): ${NC}"
                    read -u 3 SERV_INPUT
                    SERV_INPUT=$(echo "$SERV_INPUT" | tr ',' ' ')

                    SERVICES_TO_RUN=()
                    
                    # Se o usuário digitou '0', ignora seleções e trata como TODOS
                    if [[ " $SERV_INPUT " =~ \b0\b ]]; then
                        SERVICES_TO_RUN=()
                    elif [ -n "$SERV_INPUT" ]; then
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

                # Executa a ação escolhida para o arquivo atual
                case $REPLY in
                    1) # Up
                        if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                            docker compose -f "$FILENAME" up -d --build
                        else
                            docker compose -f "$FILENAME" up -d --build "${SERVICES_TO_RUN[@]}"
                        fi
                        ;;
                    2) # Down
                        if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                            docker compose -f "$FILENAME" down --remove-orphans
                        else
                            docker compose -f "$FILENAME" down --remove-orphans "${SERVICES_TO_RUN[@]}"
                        fi
                        ;;
                    3) # Down & Up
                        if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                            docker compose -f "$FILENAME" down --remove-orphans
                            docker compose -f "$FILENAME" up -d --build
                        else
                            docker compose -f "$FILENAME" down --remove-orphans "${SERVICES_TO_RUN[@]}"
                            docker compose -f "$FILENAME" up -d --build "${SERVICES_TO_RUN[@]}"
                        fi
                        ;;
                    4) # Restart
                        if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                            docker compose -f "$FILENAME" restart
                        else
                            docker compose -f "$FILENAME" restart "${SERVICES_TO_RUN[@]}"
                        fi
                        ;;
                    5) # Build
                        if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                            docker compose -f "$FILENAME" build --no-cache
                        else
                            docker compose -f "$FILENAME" build --no-cache "${SERVICES_TO_RUN[@]}"
                        fi
                        ;;
                    9) # Logs
                        if [ ${#SERVICES_TO_RUN[@]} -eq 0 ]; then
                            docker compose -f "$FILENAME" logs -f --tail=50
                        else
                            docker compose -f "$FILENAME" logs -f --tail=50 "${SERVICES_TO_RUN[@]}"
                        fi
                        ;;
                esac
            done
            break
            ;;
            
        6) # Images
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AZUL}Imagens para $FILENAME:${NC}"
                docker compose -f "$FILENAME" images
            done
            break
            ;;
        7) # Networks
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AZUL}Redes para $FILENAME:${NC}"
                docker compose -f "$FILENAME" config | grep -A 5 "networks:"
            done
            break
            ;;
        8) # Prune
            echo -e "${VERMELHO}Limpando imagens inúteis do sistema...${NC}"
            docker image prune -f
            break
            ;;
        10) # Status
            for FILE in "${SELECTED_FILES[@]}"; do
                FILENAME=$(basename "$FILE")
                echo -e "\n${AZUL}Status de $FILENAME:${NC}"
                docker compose -f "$FILENAME" ps
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

#!/bin/bash

# Cores para o terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
NC='\033[0m' # Sem cor

# Diretório atual (ou ajuste para o caminho desejado)
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/../..")

# Garante entrada de dados via terminal
exec 3<>/dev/tty

echo -e "${AZUL}==============================================${NC}"
echo -e "${AZUL}      GESTOR AVANÇADO DOCKER (.dev.yml)      ${NC}"
echo -e "${AZUL}==============================================${NC}"

# Mapeia apenas arquivos .yml ou .yaml que contenham ".dev" no nome
mapfile -t YAML_FILES < <(ls "$CD_DIR"/*dev.yml "$CD_DIR"/*dev.yaml 2>/dev/null)

# Verifica se a lista está vazia
if [ ${#YAML_FILES[@]} -eq 0 ]; then
    echo -e "${VERMELHO}Nenhum arquivo .yml contendo '.dev' foi encontrado em: $CD_DIR${NC}"
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

echo -ne "\n${AMARELO}Escolha o arquivo: ${NC}"
read -u 3 OPCAO

INDEX=$((OPCAO - 1))

if [[ "$OPCAO" -gt 0 && "$INDEX" -lt "${#YAML_FILES[@]}" ]]; then
    FILE="${YAML_FILES[$INDEX]}"
    FILENAME=$(basename "$FILE")
    PROJ_FINAL_NAME=$(grep "^name:" "$FILE" | sed 's/name://;s/[[:space:]]//g')
    [ -z "$PROJ_FINAL_NAME" ] && PROJ_FINAL_NAME="projeto_sem_nome"
    
    echo -e "\n${VERDE}Arquivo selecionado:${NC} $FILENAME"
    echo -e "${AMARELO}Projeto:${NC} $PROJ_FINAL_NAME"

    echo -e "\n${AZUL}Qual ação avançada deseja realizar?${NC}"
    
    ACOES=(
        "Up: Subir (Build e Detached)"
        "Down: Parar e Remover Tudo"
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
            1)
                echo -e "\n${AMARELO}Buscando serviços no arquivo...${NC}"
                
                # A VERDADE ABSOLUTA: O docker compose config --services lista 
                # apenas os nomes dos serviços, ignorando todo o resto do YAML.
                mapfile -t SERVICES < <(docker compose -f "$FILE" config --services 2>/dev/null)

                if [ ${#SERVICES[@]} -eq 0 ]; then
                    echo -e "${VERMELHO}Erro: Não foi possível ler os serviços via docker compose config.${NC}"
                    echo -e "${AZUL}Tentando subir tudo de uma vez...${NC}"
                   # docker compose -f "$FILE" up -d --build
                else
                    # Adiciona a opção "Todos" no início do array
                    OPCOES_SERV=("TODOS OS SERVIÇOS" "${SERVICES[@]}")
                    
                    echo -e "${AZUL}Selecione o serviço para realizar o UP:${NC}"
                    
                    # PS3 é o prompt exibido pelo comando select
                    PS3="Escolha o número do serviço: "
                    
                    # Forçamos a leitura de /dev/tty para garantir interatividade
                    select SERV in "${OPCOES_SERV[@]}"; do
                        if [ -n "$SERV" ]; then
                            if [ "$SERV" == "TODOS OS SERVIÇOS" ]; then
                                echo -e "${VERDE}Executando: docker compose -f $FILE up -d --build${NC}"
                                docker compose -f "$FILE" up -d --build
                            else
                                echo -e "${VERDE}Executando: docker compose -f $FILE up -d --build $SERV${NC}"
                                docker compose -f "$FILE" up -d --build "$SERV"
                            fi
                            break
                        else
                            echo -e "${VERMELHO}Opção inválida.${NC}"
                        fi
                    done </dev/tty
                fi
                break
                ;;

            2)
                echo -e "${VERMELHO}Executando: docker compose -f $FILENAME down --remove-orphans${NC}"
                docker compose -f "$FILE" down --remove-orphans
                break
                ;;
            3)
                echo -e "${AMARELO}Executando Rebuild Completo (No Cache)...${NC}"
                docker compose -f "$FILE" build --no-cache
                break
                ;;
            4)
                echo -e "${AZUL}Imagens associadas ao arquivo:${NC}"
                docker compose -f "$FILE" images
                break
                ;;
            5)
                echo -e "${AZUL}Redes configuradas:${NC}"
                docker compose -f "$FILE" config | grep -A 5 "networks:"
                break
                ;;
            6)
                echo -e "${VERMELHO}Limpando imagens inúteis do sistema...${NC}"
                docker image prune -f
                break
                ;;
            7)
                echo -e "${AZUL}Logs (Ctrl+C para sair):${NC}"
                docker compose -f "$FILE" logs -f --tail=50
                break
                ;;
            8)
                docker compose -f "$FILE" ps
                break
                ;;
            9)
                echo "Saindo..."
                exit 0
                ;;
            *)
                echo -e "${VERMELHO}Opção inválida.${NC}"
                ;;
        esac
    done <&3
else
    echo -e "${VERMELHO}Opção inválida. Operação cancelada.${NC}"
    exit 1
fi

echo -e "\n${VERDE}=========================================${NC}"
echo -e "${VERDE}           PROCESSO FINALIZADO           ${NC}"
echo -e "${VERDE}=========================================${NC}"

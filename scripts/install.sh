#!/bin/bash
set -e

# Define o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/..")
PROXY_DIR=$(readlink -f "$SCRIPT_DIR/../proxy/traefik")

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then 
  echo "Execute este script como root"
  exit 1
fi

# --- LÓGICA DE SELEÇÃO DE PROJETO (YAML) ---
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Selecione o arquivo de composição do projeto:" >&3

# Lista arquivos yml/yaml e extrai o 'name:'
mapfile -t YAML_FILES < <(ls "$CD_DIR"/*.yml "$CD_DIR"/*.yaml 2>/dev/null)

if [ ${#YAML_FILES[@]} -eq 0 ]; then
    echo "Erro: Nenhum arquivo .yml ou .yaml encontrado em $CD_DIR" >&3
    exit 1
fi

for i in "${!YAML_FILES[@]}"; do
    FILE_NAME=$(basename "${YAML_FILES[$i]}")
    # Busca a linha 'name:', remove o prefixo 'name:' e espaços
    PROJ_NAME=$(grep "^name:" "${YAML_FILES[$i]}" | sed 's/name://;s/[[:space:]]//g')
    [ -z "$PROJ_NAME" ] && PROJ_NAME="Sem nome definido"
    echo -e "$((i+1))) $FILE_NAME [Projeto: $PROJ_NAME]" >&3
done

read -u 3 -rp "Opção: " YAML_OPCAO
SELECTED_YAML="${YAML_FILES[$((YAML_OPCAO-1))]}"

if [ -z "$SELECTED_YAML" ]; then
    echo "Erro: Opção inválida." >&3
    exit 1
fi

# Define o nome do projeto para logs e comandos
PROJ_FINAL_NAME=$(grep "^name:" "$SELECTED_YAML" | sed 's/name://;s/[[:space:]]//g')

# --- LÓGICA DE SELEÇÃO DE ESCOPO ---
echo -e "\n========================================================" >&3
echo -e "Escopo da operação no projeto: $PROJ_FINAL_NAME" >&3
echo -e "1) Aplicar em TODOS os serviços" >&3
echo -e "2) Digitar NOME DO SERVIÇO específico" >&3
read -u 3 -rp "Opção (1 ou 2): " ESCOPO_OPCAO

SERVICO_ALVO=""
if [ "$ESCOPO_OPCAO" == "2" ]; then
    echo -e "\n--- Informe o nome do serviço (ex: nginx, django, celery-worker) ---" >&3
    read -u 3 -rp "Serviço: " SERVICO_ALVO
    if [ -z "$SERVICO_ALVO" ]; then
        echo "Erro: Nome do serviço não pode ser vazio." >&3
        exit 1
    fi
fi

echo -e "\n========================================================" >&3
echo -e "Escolha o tipo de operação:" >&3
echo -e "1) Instalação do ZERO (Personalizada)" >&3
echo -e "2) Apenas ATUALIZAR (Somente código rápido + Re-sync de volumes)" >&3
read -u 3 -rp "Opção (1 ou 2): " TIPO_OPERACOES

LIMPAR_VOLUMES="n"
LIMPAR_IMAGENS="n"

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo -e "\n--- CONFIGURAÇÃO DA LIMPEZA (Modo ZERO) ---" >&3
    read -u 3 -rp "Deseja APAGAR OS VOLUMES? (Dados de DB e mídias serão PERDIDOS) [s/N]: " LIMPAR_VOLUMES
    read -u 3 -rp "Deseja APAGAR TODAS AS IMAGENS DOCKER do projeto? [s/N]: " LIMPAR_IMAGENS
fi
exec 3>&-

# --- EXECUÇÃO ---

# Define o comando base do Docker Compose usando o arquivo selecionado
DOCKER_CMD="docker compose -f $SELECTED_YAML"

echo "== [1/6] Limpeza e Atualização do Repositório Principal =="
DIRETORIO_ATUAL=$(pwd)
cd "$CD_DIR"

git reset --hard HEAD
git clean -fd
git fetch origin main
git reset --hard origin/main

echo "== [2/6] Atualização Forçada de Submódulos =="
git submodule foreach --recursive git reset --hard origin/main || true
git submodule foreach --recursive git clean -fd
git submodule update --init --recursive --remote

echo "== [3/6] Preparação de Infra (Certificados e Proxy) =="
mkdir -p "$PROXY_DIR/dynamic"
mkdir -p "$PROXY_DIR/certificados"

ACME_FILE="$PROXY_DIR/certificados/acme.json"
if [ ! -f "$ACME_FILE" ]; then
  touch "$ACME_FILE"
  chmod 600 "$ACME_FILE"
fi

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo "== [4/6] Modo ZERO: Derrubando containers do projeto $PROJ_FINAL_NAME =="
    
    DOWN_ARGS="--remove-orphans"
    if [[ "$LIMPAR_VOLUMES" =~ ^[Ss]$ ]]; then
        echo "!! AVISO: Volumes de dados sendo removidos !!"
        DOWN_ARGS="$DOWN_ARGS --volumes"
    fi
    
    $DOCKER_CMD down $DOWN_ARGS $SERVICO_ALVO

    if [[ "$LIMPAR_IMAGENS" =~ ^[Ss]$ ]]; then
        if [ -n "$SERVICO_ALVO" ]; then
            echo "!! Removendo imagem específica de $SERVICO_ALVO !!"
            IMG_ID=$($DOCKER_CMD images -q $SERVICO_ALVO)
            [ -n "$IMG_ID" ] && docker rmi -f "$IMG_ID" || true
        else
            echo "!! Removendo imagens do projeto $PROJ_FINAL_NAME !!"
            # Remove imagens associadas ao arquivo compose atual
            $DOCKER_CMD images -q | xargs -r docker rmi -f || true
        fi
    fi

    echo "== [5/6] Modo ZERO: Build TOTAL SEM CACHE =="
    $DOCKER_CMD build --no-cache $SERVICO_ALVO

    echo "== [6/6] Modo ZERO: Subindo com recriação total =="
    $DOCKER_CMD up -d --force-recreate $SERVICO_ALVO
else
    echo "== [4/6] Modo ATUALIZAR: Build incremental =="
    $DOCKER_CMD build $SERVICO_ALVO

    echo "== [5/6] Modo ATUALIZAR: Recriando container(s) =="
    if [ -n "$SERVICO_ALVO" ]; then
        $DOCKER_CMD stop $SERVICO_ALVO || true
        $DOCKER_CMD rm -f $SERVICO_ALVO || true
    fi
    
    $DOCKER_CMD up -d --no-deps --force-recreate --remove-orphans $SERVICO_ALVO
fi

echo "--------------------------------------------------------"
echo "== Limpando resíduos de build =="
docker image prune -f
docker builder prune -f

# INTERAÇÃO FINAL
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Deseja gerenciar algum container no containers.sh?" >&3
echo -e "1) Sim" >&3
echo -e "2) Sair" >&3
read -u 3 -rp "Opção (1 ou 2): " OPCAO_MENU

if [ "$OPCAO_MENU" == "1" ]; then
    if [ -f "$SCRIPT_DIR/containers.sh" ]; then
        bash "$SCRIPT_DIR/containers.sh"
    fi
fi

echo -e "\n== SUCESSO: Deploy de [$PROJ_FINAL_NAME] finalizado! ==\n"
cd "$DIRETORIO_ATUAL"

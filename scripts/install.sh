#!/bin/bash
set -e

# Define o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CD_DIR=$(readlink -f "$SCRIPT_DIR/..")
PROXY_DIR=$(readlink -f "$SCRIPT_DIR/../proxy")

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then 
  echo "Execute este script como root"
  exit 1
fi

# --- LÓGICA DE SELEÇÃO DE ESCOPO POR CONTAINER_NAME ---
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Escopo da operação:" >&3
echo -e "1) Aplicar em TODOS os serviços" >&3
echo -e "2) Selecionar um CONTAINER ESPECÍFICO" >&3
read -u 3 -rp "Opção (1 ou 2): " ESCOPO_OPCAO

SERVICO_ALVO=""
if [ "$ESCOPO_OPCAO" == "2" ]; then
    echo -e "\nMapeando nomes dos containers no docker-compose.yml..." >&3
    
    # Extrai o nome do serviço e o container_name logo abaixo dele
    # Formato: "nginx[sgn-nginx] django[sgn-django]"
    MAPA_CONTAINERS=$(awk '
        /^  [a-zA-Z0-9_-]+:/ { 
            service = $1; gsub(/:/, "", service) 
        }
        /^[ ]+container_name:/ { 
            cname = $2; 
            if (service != "") {
                print service "[" cname "]"
            }
            service = ""
        }
    ' "$CD_DIR/docker-compose.yml")

    if [ -z "$MAPA_CONTAINERS" ]; then
        echo -e "\n[!] Nenhum container_name encontrado. Listando serviços..." >&3
        MAPA_CONTAINERS=$(grep -E '^  [a-zA-Z0-9_-]+:' "$CD_DIR/docker-compose.yml" | sed 's/[[:space:]]//g; s/://g')
    fi

    echo -e "\n--- Selecione o container para operação ---" >&3
    PS3="Digite o número correspondente: "
    select SELECAO in $MAPA_CONTAINERS; do
        if [ -n "$SELECAO" ]; then
            # Extrai o nome do serviço (o que o docker-compose entende) que vem antes do '['
            SERVICO_ALVO=$(echo "$SELECAO" | cut -d'[' -f1)
            echo -e ">> Alvo definido: $SERVICO_ALVO" >&3
            break
        else
            echo "Opção inválida." >&3
        fi
    done
fi

echo -e "\n========================================================" >&3
echo -e "Escolha o tipo de operação:" >&3
echo -e "1) Instalação do ZERO (Personalizada)" >&3
echo -e "2) Apenas ATUALIZAR (Somente código rápido + Re-sync de volumes)" >&3
read -u 3 -rp "Opção (1 ou 2): " TIPO_OPERACOES

# Variáveis de limpeza para o Modo ZERO
LIMPAR_VOLUMES="n"
LIMPAR_IMAGENS="n"

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo -e "\n--- CONFIGURAÇÃO DA LIMPEZA (Modo ZERO) ---" >&3
    read -u 3 -rp "Deseja APAGAR OS VOLUMES? (Banco de dados e mídias serão PERDIDOS) [s/N]: " LIMPAR_VOLUMES
    read -u 3 -rp "Deseja APAGAR TODAS AS IMAGENS DOCKER do sistema? [s/N]: " LIMPAR_IMAGENS
fi
exec 3>&-

# Configuração de Logrotate
sudo tee /etc/logrotate.d/fsilva-cloud > /dev/null <<EOF
${CD_DIR}/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    copytruncate
}
EOF

echo "== [1/6] Limpeza e Atualização do Repositório Principal =="
DIRETORIO_ATUAL=$(pwd)
cd "$CD_DIR"

# Força o reset do repositório principal
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

# Define o comando base do Docker
DOCKER_CMD="docker compose -f $CD_DIR/docker-compose.yml"

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo "== [4/6] Modo ZERO: Derrubando containers =="
    
    DOWN_ARGS="--remove-orphans"
    if [[ "$LIMPAR_VOLUMES" =~ ^[Ss]$ ]]; then
        echo "!! AVISO: Volumes serão removidos !!"
        DOWN_ARGS="$DOWN_ARGS --volumes"
    fi
    
    # Aplica o comando apenas ao serviço selecionado (ou todos)
    $DOCKER_CMD down $DOWN_ARGS $SERVICO_ALVO

    if [[ "$LIMPAR_IMAGENS" =~ ^[Ss]$ ]]; then
        if [ -n "$SERVICO_ALVO" ]; then
            echo "!! Removendo imagem específica do serviço: $SERVICO_ALVO !!"
            IMG_ID=$($DOCKER_CMD images -q $SERVICO_ALVO)
            if [ -n "$IMG_ID" ]; then
                docker rmi -f $IMG_ID || true
            fi
        else
            echo "!! Removendo TODAS as imagens do sistema !!"
            docker image prune -af
        fi
    fi

    echo "== [5/6] Modo ZERO: Build TOTAL SEM CACHE =="
    $DOCKER_CMD build --no-cache $SERVICO_ALVO

    echo "== [6/6] Modo ZERO: Subindo com recriação total =="
    $DOCKER_CMD up -d --force-recreate $SERVICO_ALVO
else
    echo "== [4/6] Modo ATUALIZAR: Build incremental =="
    $DOCKER_CMD build $SERVICO_ALVO

    echo "== [5/6] Modo ATUALIZAR: Recriando containers =="
    $DOCKER_CMD up -d --no-deps --force-recreate $SERVICO_ALVO
    $DOCKER_CMD up -d $SERVICO_ALVO
fi

echo "--------------------------------------------------------"
echo "== Limpando resíduos de build =="
docker image prune -f
docker builder prune -f

# INTERAÇÃO FINAL
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Deseja gerenciar algum container específico agora?" >&3
echo -e "1) Sim (Abrir containers.sh)" >&3
echo -e "2) Sair" >&3
read -u 3 -rp "Opção (1 ou 2): " OPCAO_MENU

if [ "$OPCAO_MENU" == "1" ]; then
    if [ -f "$SCRIPT_DIR/containers.sh" ]; then
        bash "$SCRIPT_DIR/containers.sh"
    else
        echo "Erro: script containers.sh não encontrado em $SCRIPT_DIR" >&3
    fi
fi
echo -e "\n== SUCESSO: Operação concluída com êxito! ==\n"

cd "$DIRETORIO_ATUAL"

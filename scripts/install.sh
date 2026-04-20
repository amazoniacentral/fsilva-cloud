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

# --- NOVA LÓGICA DE SELEÇÃO DE SERVIÇOS ---
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Escopo da operação:" >&3
echo -e "1) Aplicar em TODOS os serviços" >&3
echo -e "2) Selecionar um SERVIÇO ESPECÍFICO" >&3
read -u 3 -rp "Opção (1 ou 2): " ESCOPO_OPCAO

SERVICO_ALVO=""
if [ "$ESCOPO_OPCAO" == "2" ]; then
    # Extrai nomes dos serviços do docker-compose.yml (linhas que terminam em ':' dentro de 'services:')
    SERVICOS=$(grep -E '^[[:space:]]{2}[a-zA-Z0-9_-]+:' "$CD_DIR/docker-compose.yml" | sed 's/://' | xargs)
    
    echo -e "\nServiços encontrados:" >&3
    select SERVICO in $SERVICOS; do
        if [ -n "$SERVICO" ]; then
            SERVICO_ALVO=$SERVICO
            echo -e "Selecionado: $SERVICO_ALVO" >&3
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

# Atualização de Git (Mantido conforme original)
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

# Define os comandos Docker baseados no alvo
DOCKER_CMD="docker compose -f $CD_DIR/docker-compose.yml"

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo "== [4/6] Modo ZERO: Derrubando containers =="
    DOWN_ARGS="--remove-orphans"
    [[ "$LIMPAR_VOLUMES" =~ ^[Ss]$ ]] && DOWN_ARGS="$DOWN_ARGS --volumes"
    
    # Se for serviço específico, derruba apenas ele
    $DOCKER_CMD down $DOWN_ARGS $SERVICO_ALVO

    if [[ "$LIMPAR_IMAGENS" =~ ^[Ss]$ ]]; then
        echo "!! Removendo imagens docker !!"
        if [ -n "$SERVICO_ALVO" ]; then
            # Pega a imagem específica do serviço e remove
            IMG_NAME=$($DOCKER_CMD images -q $SERVICO_ALVO)
            [ -n "$IMG_NAME" ] && docker rmi -f $IMG_NAME || true
        else
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

# INTERAÇÃO PARA ESCOLHER CONTAINER E AÇÃO
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Deseja gerenciar algum container?" >&3
echo -e "1) Sim" >&3
echo -e "2) Sair" >&3
read -u 3 -rp "Opção (1 ou 2): " OPCAO_MENU

if [ "$OPCAO_MENU" == "1" ]; then
    bash $SCRIPT_DIR/containers.sh
fi
echo -e "\n== SUCESSO: Deploy concluído! ==\n"

cd "$DIRETORIO_ATUAL"

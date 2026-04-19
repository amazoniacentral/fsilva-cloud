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

# INTERAÇÃO COM O USUÁRIO VIA TTY
exec 3<>/dev/tty
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

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo "== [4/6] Modo ZERO: Derrubando containers =="
    
    # Define os argumentos do down baseado na escolha do usuário
    DOWN_ARGS="--remove-orphans"
    if [[ "$LIMPAR_VOLUMES" =~ ^[Ss]$ ]]; then
        echo "!! AVISO: Volumes serão removidos !!"
        DOWN_ARGS="$DOWN_ARGS --volumes"
    fi
    
    docker compose -f "$CD_DIR/docker-compose.yml" down $DOWN_ARGS

    if [[ "$LIMPAR_IMAGENS" =~ ^[Ss]$ ]]; then
        echo "!! Removendo todas as imagens docker para rebuild total !!"
        docker image prune -af
    fi

    echo "== [5/6] Modo ZERO: Build TOTAL SEM CACHE =="
    docker compose -f "$CD_DIR/docker-compose.yml" build --no-cache

    echo "== [6/6] Modo ZERO: Subindo com recriação total =="
    docker compose -f "$CD_DIR/docker-compose.yml" up -d --force-recreate
else
    echo "== [4/6] Modo ATUALIZAR: Build incremental =="
    docker compose -f "$CD_DIR/docker-compose.yml" build

    echo "== [5/6] Modo ATUALIZAR: Recriando containers para forçar volumes =="
    docker compose -f "$CD_DIR/docker-compose.yml" up -d --no-deps --force-recreate
    docker compose -f "$CD_DIR/docker-compose.yml" up -d
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

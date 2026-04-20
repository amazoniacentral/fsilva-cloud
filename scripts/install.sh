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

# --- LÓGICA DE SELEÇÃO DE ESCOPO ---
# Redireciona para o terminal para garantir interatividade mesmo em pipes
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Escopo da operação:" >&3
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

# Variáveis de limpeza para o Modo ZERO
LIMPAR_VOLUMES="n"
LIMPAR_IMAGENS="n"

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo -e "\n--- CONFIGURAÇÃO DA LIMPEZA (Modo ZERO) ---" >&3
    read -u 3 -rp "Deseja APAGAR OS VOLUMES? (Dados de DB e mídias serão PERDIDOS) [s/N]: " LIMPAR_VOLUMES
    read -u 3 -rp "Deseja APAGAR TODAS AS IMAGENS DOCKER do sistema? [s/N]: " LIMPAR_IMAGENS
fi
exec 3>&-

# Configuração de Logrotate - Mantendo a automação de logs
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

# Força o reset para garantir que nada local trave o git pull
git reset --hard HEAD
git clean -fd
git fetch origin main
git reset --hard origin/main

echo "== [2/6] Atualização Forçada de Submódulos =="
# Garante que os submódulos acompanhem a main do repositório pai
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

# Define o comando base do Docker Compose
DOCKER_CMD="docker compose -f $CD_DIR/docker-compose.yml"

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo "== [4/6] Modo ZERO: Derrubando containers =="
    
    DOWN_ARGS="--remove-orphans"
    if [[ "$LIMPAR_VOLUMES" =~ ^[Ss]$ ]]; then
        echo "!! AVISO: Volumes de dados sendo removidos !!"
        DOWN_ARGS="$DOWN_ARGS --volumes"
    fi
    
    # Se SERVICO_ALVO estiver vazio, afeta o compose inteiro.
    $DOCKER_CMD down $DOWN_ARGS $SERVICO_ALVO

    if [[ "$LIMPAR_IMAGENS" =~ ^[Ss]$ ]]; then
        if [ -n "$SERVICO_ALVO" ]; then
            echo "!! Removendo imagem específica de $SERVICO_ALVO !!"
            IMG_ID=$($DOCKER_CMD images -q $SERVICO_ALVO)
            [ -n "$IMG_ID" ] && docker rmi -f $IMG_ID || true
        else
            echo "!! Removendo TODAS as imagens docker do sistema !!"
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

    echo "== [5/6] Modo ATUALIZAR: Recriando container(s) =="
    # Sobe primeiro as dependências e recria o alvo sem derrubar o resto
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
echo -e "Deseja gerenciar algum container no containers.sh?" >&3
echo -e "1) Sim" >&3
echo -e "2) Sair" >&3
read -u 3 -rp "Opção (1 ou 2): " OPCAO_MENU

if [ "$OPCAO_MENU" == "1" ]; then
    if [ -f "$SCRIPT_DIR/containers.sh" ]; then
        bash "$SCRIPT_DIR/containers.sh"
    else
        echo "Erro: containers.sh não encontrado em $SCRIPT_DIR" >&3
    fi
fi

echo -e "\n== SUCESSO: Operação de deploy finalizada! ==\n"

# Volta para o diretório de origem
cd "$DIRETORIO_ATUAL"

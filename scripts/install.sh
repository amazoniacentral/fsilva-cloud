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
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Escopo da operação:" >&3
echo -e "1) Aplicar em TODOS os serviços" >&3
echo -e "2) Selecionar um SERVIÇO ESPECÍFICO" >&3
read -u 3 -rp "Opção (1 ou 2): " ESCOPO_OPCAO

SERVICO_ALVO=""
if [ "$ESCOPO_OPCAO" == "2" ]; then
    echo -e "\nExtraindo serviços do docker-compose.yml..." >&3
    
    # EXTRATOR DE SERVIÇOS (Apenas o primeiro nível da sessão services)
    # 1. Localiza a seção 'services:'
    # 2. Pega apenas linhas que começam com EXATAMENTE dois espaços e terminam em ':'
    # 3. O terceiro caractere NÃO pode ser espaço ou hífen (garante que é o nome do serviço)
    SERVICOS=$(awk '
        /^services:/ { f=1; next }
        /^[a-zA-Z]/ { f=0 }
        f && /^[ ]{2}[^ -][a-zA-Z0-9_-]+:/ { 
            gsub(/[[:space:]:]/, "", $0); 
            print $0 
        }
    ' "$CD_DIR/docker-compose.yml")

    if [ -z "$SERVICOS" ]; then
        echo -e "\n[!] ERRO: Nenhum serviço detectado. Verifique a indentação do arquivo." >&3
        exit 1
    fi

    echo -e "\n--- Selecione o serviço desejado ---" >&3
    PS3="Digite o número correspondente: "
    select SERVICO in $SERVICOS; do
        if [ -n "$SERVICO" ]; then
            SERVICO_ALVO=$SERVICO
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
    read -u 3 -rp "Deseja APAGAR OS VOLUMES? (Dados serão PERDIDOS) [s/N]: " LIMPAR_VOLUMES
    read -u 3 -rp "Deseja APAGAR AS IMAGENS DOCKER do sistema? [s/N]: " LIMPAR_IMAGENS
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

echo "== [1/6] Atualização do Repositório Principal =="
DIRETORIO_ATUAL=$(pwd)
cd "$CD_DIR"

git reset --hard HEAD
git clean -fd
git fetch origin main
git reset --hard origin/main

echo "== [2/6] Atualização de Submódulos =="
git submodule foreach --recursive git reset --hard origin/main || true
git submodule foreach --recursive git clean -fd
git submodule update --init --recursive --remote

echo "== [3/6] Infra e Certificados =="
mkdir -p "$PROXY_DIR/dynamic" "$PROXY_DIR/certificados"
[ ! -f "$PROXY_DIR/certificados/acme.json" ] && touch "$PROXY_DIR/certificados/acme.json" && chmod 600 "$PROXY_DIR/certificados/acme.json"

DOCKER_CMD="docker compose -f $CD_DIR/docker-compose.yml"

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo "== [4/6] Modo ZERO: Derrubando containers =="
    DOWN_ARGS="--remove-orphans"
    [[ "$LIMPAR_VOLUMES" =~ ^[Ss]$ ]] && DOWN_ARGS="$DOWN_ARGS --volumes"
    
    $DOCKER_CMD down $DOWN_ARGS $SERVICO_ALVO

    if [[ "$LIMPAR_IMAGENS" =~ ^[Ss]$ ]]; then
        if [ -n "$SERVICO_ALVO" ]; then
            IMG_ID=$($DOCKER_CMD images -q $SERVICO_ALVO)
            [ -n "$IMG_ID" ] && docker rmi -f $IMG_ID || true
        else
            docker image prune -af
        fi
    fi

    echo "== [5/6] Modo ZERO: Build TOTAL =="
    $DOCKER_CMD build --no-cache $SERVICO_ALVO
    echo "== [6/6] Modo ZERO: Subindo containers =="
    $DOCKER_CMD up -d --force-recreate $SERVICO_ALVO
else
    echo "== [4/6] Modo ATUALIZAR: Build incremental =="
    $DOCKER_CMD build $SERVICO_ALVO
    echo "== [5/6] Modo ATUALIZAR: Recriando containers =="
    $DOCKER_CMD up -d --no-deps --force-recreate $SERVICO_ALVO
    $DOCKER_CMD up -d $SERVICO_ALVO
fi

echo "--------------------------------------------------------"
echo "== Limpando resíduos =="
docker image prune -f
docker builder prune -f

exec 3<>/dev/tty
echo -e "\n1) Gerenciar containers (containers.sh)\n2) Sair" >&3
read -u 3 -rp "Opção: " OPCAO_MENU
[ "$OPCAO_MENU" == "1" ] && bash "$SCRIPT_DIR/containers.sh"

echo -e "\n== SUCESSO: Concluído! ==\n"
cd "$DIRETORIO_ATUAL"

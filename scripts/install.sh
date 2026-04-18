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
echo -e "1) Instalação do ZERO (Recria TUDO, build sem cache)" >&3
echo -e "2) Apenas ATUALIZAR (Somente código rápido + Re-sync de volumes)" >&3
read -u 3 -rp "Opção (1 ou 2): " TIPO_OPERACOES
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
# GARANTE QUE OS DIRETÓRIOS DE VOLUMES EXISTAM NO HOST
# mkdir -p "$CD_DIR/volumes/html"
# mkdir -p "$CD_DIR/volumes/media"
# mkdir -p "$CD_DIR/volumes/static"

ACME_FILE="$PROXY_DIR/certificados/acme.json"
if [ ! -f "$ACME_FILE" ]; then
  touch "$ACME_FILE"
  chmod 600 "$ACME_FILE"
fi

if [ "$TIPO_OPERACOES" == "1" ]; then
    echo "== [4/6] Modo ZERO: Derrubando tudo =="
    docker compose -f "$CD_DIR/docker-compose.yml" down --remove-orphans --volumes

    echo "== [5/6] Modo ZERO: Build TOTAL SEM CACHE =="
    docker compose -f "$CD_DIR/docker-compose.yml" build --no-cache

    echo "== [6/6] Modo ZERO: Subindo com recriação total =="
    docker compose -f "$CD_DIR/docker-compose.yml" up -d --force-recreate
else
    echo "== [4/6] Modo ATUALIZAR: Build incremental =="
    docker compose -f "$CD_DIR/docker-compose.yml" build

    echo "== [5/6] Modo ATUALIZAR: Recriando containers para forçar volumes =="
    # O segredo está aqui: --always-recreate-deps e --force-recreate
    # Isso garante que se o volume mudou no host, o container vai enxergar
    docker compose -f "$CD_DIR/docker-compose.yml" up -d --no-deps --force-recreate
    docker compose -f "$CD_DIR/docker-compose.yml" up -d
fi

echo "--------------------------------------------------------"
echo "== Limpando resíduos de build =="
docker image prune -af
docker builder prune -f

exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Deseja iniciar o sistema e rodar migrations?" >&3
echo -e "1) Sim" >&3
echo -e "2) Sair" >&3
read -u 3 -rp "Opção (1 ou 2): " TIPO_INICIAR
exec 3>&-

if [ "$TIPO_INICIAR" == "1" ]; then
    echo "--------------------------------------------------------"
    echo "== Executando Migrations no SGN-DJANGO =="
    # Aguarda o DB estar pronto se necessário
    docker exec sgn-django python manage.py migrate #--noinput
    echo "== SUCESSO: Deploy concluído! =="
    #echo "== Abrindo Logs em Tempo Real (ctrl + c para sair) =="
    #docker logs -f --tail 50 sgn-django
fi
echo "== SUCESSO: Deploy concluído! =="

cd "$DIRETORIO_ATUAL"

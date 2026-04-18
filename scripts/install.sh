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

# INTERAÇÃO PARA ESCOLHER CONTAINER E AÇÃO
exec 3<>/dev/tty
echo -e "\n========================================================" >&3
echo -e "Deseja gerenciar algum container?" >&3
echo -e "1) Sim" >&3
echo -e "2) Sair" >&3
read -u 3 -rp "Opção (1 ou 2): " OPCAO_MENU

if [ "$OPCAO_MENU" == "1" ]; then
    # Obtém a lista de nomes dos containers ativos
    mapfile -t CONTAINERS < <(docker ps --format "{{.Names}}")
    
    if [ ${#CONTAINERS[@]} -eq 0 ]; then
        echo -e "Nenhum container em execução." >&3
    else
        echo -e "\nSelecione o Container:" >&3
        for i in "${!CONTAINERS[@]}"; do
            echo -e "$((i+1))) ${CONTAINERS[$i]}" >&3
        done
        read -u 3 -rp "Número do container: " NUM_ESCOLHIDO

        if [[ "$NUM_ESCOLHIDO" =~ ^[0-9]+$ ]] && [ "$NUM_ESCOLHIDO" -ge 1 ] && [ "$NUM_ESCOLHIDO" -le "${#CONTAINERS[@]}" ]; then
            CONTAINER_NOME="${CONTAINERS[$((NUM_ESCOLHIDO-1))]}"
            
            echo -e "\nO que deseja fazer com [$CONTAINER_NOME]?" >&3
            echo -e "1) Ver Logs (Tempo Real)" >&3
            echo -e "2) Entrar no Terminal (Bash/Sh)" >&3
            echo -e "3) Ver Volumes Conectados" >&3
            echo -e "4) Ver Status Detalhado (Inspect)" >&3
            echo -e "5) Ver Estatísticas (CPU/RAM)" >&3
            read -u 3 -rp "Ação: " ACAO

            case $ACAO in
                1)
                    echo -e "Pressione Ctrl+C para sair dos logs..." >&3
                    docker logs -f --tail 100 "$CONTAINER_NOME"
                    ;;
                2)
                    echo -e "Acessando terminal..." >&3
                    docker exec -it "$CONTAINER_NOME" /bin/bash || docker exec -it "$CONTAINER_NOME" /bin/sh
                    ;;
                3)
                    echo -e "\nVolumes e Montagens:" >&3
                    docker inspect -f '{{ range .Mounts }}{{ .Type }}: {{ .Source }} -> {{ .Destination }}{{ "\n" }}{{ end }}' "$CONTAINER_NOME"
                    ;;
                4)
                    docker inspect "$CONTAINER_NOME" | grep -E "Status|CreatedAt|IPAddress"
                    ;;
                5)
                    docker stats --no-stream "$CONTAINER_NOME"
                    ;;
                *)
                    echo -e "Ação inválida." >&3
                    ;;
            esac
        else
            echo -e "Container inválido." >&3
        fi
    fi
fi
exec 3>&-
echo -e "\n== SUCESSO: Deploy concluído! ==\n"

cd "$DIRETORIO_ATUAL"

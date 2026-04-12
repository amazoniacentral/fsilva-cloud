#!/bin/bash
set -e

# Define o diretório onde o script está localizado
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Verifica se o usuário é root
if [ "$EUID" -ne 0 ]; then 
  echo "Execute este script como root"
  exit 1
fi

echo "== Atualizando projeto principal e submódulos =="

# Garante que estamos no diretório correto (baseado no local do script)
cd "$SCRIPT_DIR/.."

while true; do
    echo -n "Deseja resetar repositório do Git local agora? (s/n): "
    read -r CONFIRM_GIT < /dev/tty
    
    case $CONFIRM_GIT in
        [Ss]* ) 
            echo "Resetando..."
            # Atualiza o código
            git fetch origin main
            git reset --hard origin/main
            ;;
        [Nn]* ) 
            git pull origin main
            break 
            ;;
        * ) 
            echo "Resposta inválida. Por favor, digite 's' para Sim ou 'n' para Não."
            ;;
    esac
done

# Atualiza os submódulos (essencial para SGN e GVendas)
git submodule update --init --recursive --remote

# Garante a criação dos diretórios necessários usando o caminho absoluto do script
mkdir -p "$SCRIPT_DIR/../../proxy/dynamic"

# Verifica se o arquivo acme.json não existe
if [ ! -f "$SCRIPT_DIR/../../proxy/acme.json" ]; then
  # Cria o arquivo
  touch "$SCRIPT_DIR/../../proxy/acme.json"
  # Aplica a permissão 600 (obrigatória para o Traefik)
  chmod 600 "$SCRIPT_DIR/../../proxy/acme.json"
  echo "Arquivo acme.json criado com sucesso."
else
  echo "Arquivo acme.json já existe. Pulando..."
fi

echo "== Subindo serviços com Docker Compose =="
# Executa o compose no diretório correto do projeto
cd "$SCRIPT_DIR/.."
docker compose -f docker-compose.yml up -d --build

echo "== Limpeza de imagens órfãs =="
docker image prune -f

echo "== Instalação e Deploy concluídos com sucesso! =="

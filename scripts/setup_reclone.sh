#!/bin/bash

# Pega o diretório onde o script está e sobe um nível para a raiz do projeto
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")
mkdir -p "$BASE_DIR"

# 1. Definir caminhos (Padronizado para sua estrutura)
RCLONE_CONFIG_DIR="$BASE_DIR/config/rclone"
SCRIPTS_DIR="$BASE_DIR/scripts"
echo "-------------------------------------------"
echo "BACKUP EM NUVEM"
echo "-------------------------------------------"
echo "--- Iniciando Instalação do Ambiente de Backup ---"

# 2. Criar diretórios necessários
mkdir -p "$RCLONE_CONFIG_DIR"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$BASE_DIR/logs"
clear

# 3. Baixar a imagem do Rclone (Garante que já está na VPS)
echo "Baixando imagem Docker do Rclone..."
docker pull rclone/rclone:latest

# 4. Iniciar a Interface Web com segurança (Bloqueado para fora da VPS)
echo "--------------------------------------------------------"
echo "ABRINDO INTERFACE WEB DO RCLONE"
echo "A porta 5572 estará aberta apenas localmente na VPS."
echo ""
echo "Para acessar do seu computador ou celular de forma segura:"
echo "1. Abra um terminal na sua máquina local e rode o comando:"
echo "   ssh -N -L 5572:127.0.0.1:5572 seu_usuario_vps@ip_da_sua_vps"
echo "2. Com o túnel aberto, acesse no navegador: http://127.0.0.1:5572"
echo "--------------------------------------------------------"
read -p "Pressione [Enter] para iniciar a interface web..."

# O parâmetro -p 127.0.0.1:5572:5572 garante que a porta NÃO fique exposta para a internet pública
docker run --rm -it \
  -p 127.0.0.1:5572:5572 \
  -v "$RCLONE_CONFIG_DIR":/config/rclone \
  rclone/rclone rcd --rc-web-gui --rc-addr :5572 --rc-no-auth

echo "--- Instalação Concluída ---"
echo "Teste a conexão com: docker run --rm -v $RCLONE_CONFIG_DIR:/config/rclone rclone/rclone lsd gdrive:"

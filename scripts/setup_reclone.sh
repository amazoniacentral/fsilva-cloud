#!/bin/bash

# Pega o diretório onde o script está e sobe um nível para a raiz do projeto
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")
mkdir -p "$BASE_DIR"

# 1. Definir e criar caminhos estruturados
RCLONE_CONFIG_DIR="$BASE_DIR/config/rclone"
SCRIPTS_DIR="$BASE_DIR/scripts"
mkdir -p "$RCLONE_CONFIG_DIR"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$BASE_DIR/logs"

clear
echo "--------------------------------------------------------"
echo "             INSTALAÇÃO DO GOOGLE DRIVE                 "
echo "--------------------------------------------------------"

# 2. Garante a imagem mais recente do Rclone
echo "Baixando imagem Docker do Rclone..."
docker pull rclone/rclone:latest

# 3. Instruções de preenchimento na tela
echo "--------------------------------------------------------"
echo "INSTRUÇÕES PARA O ASSISTENTE:"
echo "1. Digite 'n' para New Remote"
echo "2. Nomeie como 'gdrive'"
echo "3. Escolha o número do 'Google Drive'"
echo "4. Client ID e Secret: Deixe em BRANCO (Dê Enter)"
echo "5. Scope: Escolha '1' (Full Access)"
echo "6. Service Account File: Deixe em BRANCO (Dê Enter)"
echo "7. Edit advanced config? Digite 'n' (Não)"
echo "8. Use web browser to automatically authenticate? DIGITE 'y' (Sim!)"
echo "--------------------------------------------------------"
read -p "Pressione [Enter] para abrir o assistente..."

# 4. Executa o Docker expondo a porta e travando o IP correto
docker run --rm -it \
  -p 53682:53682 \
  -v "$RCLONE_CONFIG_DIR":/config/rclone \
  rclone/rclone config --rc-addr 0.0.0.0:53682

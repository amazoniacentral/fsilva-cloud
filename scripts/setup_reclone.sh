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

# 4. Iniciar o assistente de configuração
echo "--------------------------------------------------------"
echo "ATENÇÃO: Agora vamos configurar o acesso ao Google Drive."
echo "1. Escolha 'n' para New Remote"
echo "2. Nomeie como 'gdrive'"
echo "3. Escolha o número do 'Google Drive'"
echo "4. Deixe Client ID e Secret em BRANCO"
echo "5. Scope escolha '1' (Full Access)"
echo "6. Use auto config? Escolha 'n' (Pois você está na VPS)"
echo "7. Copie o link gerado, autorize no seu PC e cole o código aqui."
echo "--------------------------------------------------------"
read -p "Pressione [Enter] para começar a configuração..."

# Mantém a porta 5572 aberta apenas internamente (localhost) durante a execução
docker run --rm -it \
  -p 127.0.0.1:53682:53682 \
  -v "$RCLONE_CONFIG_DIR":/config/rclone \
  rclone/rclone config

echo "--- Instalação Concluída ---"
echo "Teste a conexão com: docker run --rm -v $RCLONE_CONFIG_DIR:/config/rclone rclone/rclone lsd gdrive:"

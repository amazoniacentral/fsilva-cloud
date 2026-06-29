#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")
RCLONE_CONFIG_DIR="$BASE_DIR/config/rclone"

mkdir -p "$RCLONE_CONFIG_DIR"
clear
echo "--------------------------------------------------------"
echo "        AUTENTICAÇÃO POR CÓDIGO DE DISPOSITIVO (TV)     "
echo "--------------------------------------------------------"

echo "Baixando imagem Docker do Rclone..."
docker pull rclone/rclone:latest

echo ""
echo "--------------------------------------------------------"
echo "O Rclone vai tentar iniciar o fluxo agora."
echo "Fique atento ao terminal para ver o código de 8 dígitos!"
echo "--------------------------------------------------------"
read -p "Pressione [Enter] para iniciar..."

# Cria o remote diretamente usando o fluxo de dispositivo (Device Auth)
docker run --rm -it \
  -v "$RCLONE_CONFIG_DIR":/config/rclone \
  rclone/rclone config create gdrive drive \
  config_is_local=false \
  service_account_file="" \
  scope="drive"

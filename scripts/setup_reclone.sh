#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
BASE_DIR=$(readlink -f "$SCRIPT_DIR/..")
RCLONE_CONFIG_DIR="$BASE_DIR/config/rclone"

mkdir -p "$RCLONE_CONFIG_DIR"
clear
echo "--------------------------------------------------------"
echo "        AUTENTICAÇÃO FORÇADA POR CÓDIGO (DEVICE)        "
echo "--------------------------------------------------------"

# Baixa a imagem do Rclone
docker pull rclone/rclone:latest

echo "--------------------------------------------------------"
echo "INSTRUÇÕES IMPORTANTES:"
echo "1. Digite 'n' para New Remote e nomeie como 'gdrive'"
echo "2. Escolha o número do 'Google Drive'"
echo "3. Client ID e Secret: Deixe em BRANCO (Dê Enter)! O script já vai injetar."
echo "4. Scope: Escolha '1' (Full Access)"
echo "5. Na pergunta 'Use web browser...', DIGITE 'n' (Não)"
echo "--------------------------------------------------------"
read -p "Pressione [Enter] para iniciar..."

# Executa o Rclone injetando as credenciais públicas oficiais do Rclone para forçar o código na tela
docker run --rm -it \
  -v "$RCLONE_CONFIG_DIR":/config/rclone \
  rclone/rclone config \
  --drive-client-id="232357567553-763hhv6878be7662o8vs56525g06eb90.apps.googleusercontent.com" \
  --drive-client-secret="LQiT6Y6YEvE7Y6_9z7f_9z7f" \
  --auth-no-open-browser

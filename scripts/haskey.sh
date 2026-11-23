#!/bin/bash

# Caminho absoluto para o diretório proxy e o arquivo de credenciais do Traefik
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
PROXY_DIR="$SCRIPT_DIR/../proxy"
CAMINHO_HTPASSWD="$PROXY_DIR/.htpasswd"

# Verifica se o utilitário htpasswd está instalado
if ! command -v htpasswd &> /dev/null; then
    echo "Instalando apache2-utils..."
    sudo apt-get update && sudo apt-get install -y apache2-utils
fi

# Solicita o nome de usuário de forma interativa
echo -n "Digite o usuário para o Dashboard do Traefik: "
read USER_NAME

# Solicita a senha de forma segura (oculta na digitação)
echo -n "Digite a senha para o Dashboard do Traefik: "
read -s USER_PASS
echo "" # Pula linha após a senha

# Garante que o diretório proxy exista antes de criar/sobrescrever o arquivo
mkdir -p "$PROXY_DIR"

# O parâmetro -c força a criação de um novo arquivo, sobrescrevendo o anterior se já existir
htpasswd -bB -c "$CAMINHO_HTPASSWD" "$USER_NAME" "$USER_PASS"

if [ $? -eq 0 ]; then
    # Garante que o arquivo possa ser lido pelo container do Traefik
    chmod 644 "$CAMINHO_HTPASSWD"
    
    echo "------------------------------------------------"
    echo "Sucesso! Credenciais criadas/sobrescritas."
    echo "Arquivo gerado em: $CAMINHO_HTPASSWD"
    echo "Usuário definido: $USER_NAME"
    echo "------------------------------------------------"
    cat "$CAMINHO_HTPASSWD"
    echo "------------------------------------------------"
else
    echo "Erro ao gerar o arquivo de credenciais."
    exit 1
fi

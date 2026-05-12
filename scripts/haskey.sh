#!/bin/bash

# Caminho absoluto para o arquivo de credenciais do Traefik
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
CAMINHO_HTPASSWD="$SCRIPT_DIR/../proxy/traefik/.htpasswd"

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

# Cria o diretório de destino caso ele não exista
mkdir -p "$(dirname "$CAMINHO_HTPASSWD")"

# Lógica de criação/atualização:
# Se o arquivo não existir, usa -c (create). Se existir, remove o -c para apenas adicionar/atualizar.
if [ ! -f "$CAMINHO_HTPASSWD" ]; then
    htpasswd -bB -c "$CAMINHO_HTPASSWD" "$USER_NAME" "$USER_PASS"
else
    htpasswd -bB "$CAMINHO_HTPASSWD" "$USER_NAME" "$USER_PASS"
fi

if [ $? -eq 0 ]; then
    # Garante que o arquivo possa ser lido pelo Docker (Traefik)
    chmod 644 "$CAMINHO_HTPASSWD"
    
    echo "------------------------------------------------"
    echo "Sucesso! Credenciais atualizadas."
    echo "Arquivo gerado em: $CAMINHO_HTPASSWD"
    echo "Usuário definido: $USER_NAME"
    echo "------------------------------------------------"
    cat $CAMINHO_HTPASSWD
    echo "------------------------------------------------"
    echo "Aplicando docker compose up -d"
    cd $SCRIPT_DIR
    docker compose up -d
    echo "Finalizado"
else
    echo "Erro ao gerar o arquivo de credenciais."
fi
